# TileZhan (麻雀斩) — 后端详细设计文档 v1.0

> 目标读者: Python 后端工程师
> 前置阅读: `tilezhan-architecture.md` (CTO 架构 §三-§七)
> 日期: 2026-06-07

---

## 目录

1. [项目初始化与工程规范](#一项目初始化与工程规范)
2. [数据模型与 Firestore Schema](#二数据模型与-firestore-schema)
3. [API 端点实现](#三api-端点实现)
4. [麻将引擎集成](#四麻将引擎集成)
5. [题库生成 Pipeline](#五题库生成-pipeline)
6. [SRS 后端服务](#六srs-后端服务)
7. [RevenueCat Webhook](#七revenuecat-webhook)
8. [安全中间件](#八安全中间件)
   - [8.4 NTP 防篡改](#84-ntp-防篡改-服务端时间校验)
   - [8.5 幂等性校验](#85-幂等性校验-idempotency)
   - [8.6 全局异常处理](#86-全局异常处理)
9. [后台管理与运维](#九后台管理与运维)
10. [测试策略](#十测试策略)
11. [部署配置](#十一部署配置)

---

## 一、项目初始化与工程规范

### 1.1 依赖 (requirements.txt)

```
# ── Web 框架 ──
fastapi==0.115.0
uvicorn[standard]==0.30.6
pydantic==2.9.2
pydantic-settings==2.5.2

# ── Firebase ──
firebase-admin==6.5.0
google-cloud-firestore==2.18.1

# ── 麻将引擎 ──
mahjong==1.2.3                    # 日麻算番库 (C++ binding)

# ── 任务队列 ──
celery==5.4.0
redis==5.1.1

# ── 工具 ──
httpx==0.27.2                     # 异步 HTTP (RevenueCat / Apple / Google)
slowapi==0.1.9                    # Rate Limiting
python-jose[cryptography]==3.3.0 # JWT
tenacity==8.5.0                   # 重试
structlog==24.4.0                 # 结构化日志

# ── 开发/测试 ──
pytest==8.3.3
pytest-asyncio==0.24.0
httpx (test client)
factory-boy==3.3.1
```

### 1.2 配置文件

```python
# backend/app/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # ── App ──
    APP_NAME: str = "TileZhan API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # ── Firebase ──
    FIREBASE_PROJECT_ID: str
    FIREBASE_PRIVATE_KEY: str
    FIREBASE_CLIENT_EMAIL: str
    FIRESTORE_DATABASE: str = "(default)"

    # ── RevenueCat ──
    REVENUECAT_API_KEY: str
    REVENUECAT_WEBHOOK_SECRET: str

    # ── Redis (Celery) ──
    REDIS_URL: str = "redis://localhost:6379/0"

    # ── Security ──
    RATE_LIMIT_PER_MINUTE: int = 100
    ALLOWED_ORIGINS: list[str] = ["https://tilezhan.app"]

    # ── Mahjong Engine ──
    MAHJONG_RULE_SET: str = "riichi"  # MVP: 仅日麻

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
```

### 1.3 应用入口

```python
# backend/app/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.api.v1.router import api_router
from app.core.firebase import init_firebase
from app.core.limiter import limiter


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    init_firebase()
    yield
    # Shutdown: 关闭连接池等

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

# ── 中间件 ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── 路由 ──
app.include_router(api_router, prefix="/api/v1")
```

### 1.4 项目目录结构

```
backend/
├── app/
│   ├── main.py                          # FastAPI 入口
│   ├── config.py                        # 环境配置
│   │
│   ├── api/
│   │   ├── deps.py                      # 依赖注入 (get_db, get_current_user, limiter)
│   │   └── v1/
│   │       ├── router.py                # 聚合所有子路由
│   │       ├── auth.py                  # POST /auth/*
│   │       ├── user.py                  # GET|PATCH /user/*
│   │       ├── puzzles.py               # GET|POST /puzzles/*
│   │       ├── mahjong.py               # POST /mahjong/*
│   │       ├── srs.py                   # GET|POST /srs/*
│   │       └── subscription.py          # POST /subscription/*, /webhooks/*
│   │
│   ├── core/
│   │   ├── firebase.py                  # Firebase Admin SDK 初始化 + Firestore 客户端
│   │   ├── security.py                  # JWT 解码 + 用户身份验证
│   │   ├── limiter.py                   # slowapi Rate Limiter
│   │   └── revenuecat.py                # RevenueCat REST API 封装
│   │
│   ├── domain/
│   │   ├── models/
│   │   │   ├── user.py                  # User, UserProgress (Pydantic)
│   │   │   ├── puzzle.py                # Puzzle, DailyQuest, PrecomputedResult
│   │   │   ├── tile.py                  # TileDefinition (34 张牌常量)
│   │   │   └── srs_item.py              # SrsItem, SrsReport
│   │   ├── services/
│   │   │   ├── puzzle_service.py        # 每日任务组装 + ELO 匹配
│   │   │   ├── srs_service.py           # SM-2 计算 + 到期查询
│   │   │   ├── sync_service.py          # 批量同步 + Firestore batch + LWW
│   │   │   ├── stamina_service.py       # 体力值扣减 + NTP 校验
│   │   │   └── subscription_service.py  # 订阅状态管理
│   │   └── validators/
│   │       └── tile_validator.py        # 牌 ID 白名单校验 (34 张)
│   │
│   ├── engine/
│   │   ├── shanten.py                   # 向听数计算 (Python 实现)
│   │   ├── hand_calculator.py           # 完整手牌估值 (封装 mahjong 库)
│   │   ├── ukeire.py                    # 进张数计算
│   │   └── yaku_registry.py             # 日麻 40 种役种注册表
│   │
│   └── workers/
│       ├── celery_app.py                # Celery 配置
│       ├── puzzle_generator.py          # 离线题库批量生成任务
│       └── srs_scheduler.py             # SRS 到期提醒推送 (V2)
│
├── tests/
│   ├── conftest.py                      # Fixtures (mock Firebase, test client)
│   ├── test_api/
│   │   ├── test_puzzles.py
│   │   ├── test_mahjong.py
│   │   ├── test_srs.py
│   │   └── test_subscription.py
│   ├── test_engine/
│   │   ├── test_shanten.py
│   │   ├── test_ukeire.py
│   │   └── test_hand_calculator.py
│   └── test_services/
│       ├── test_puzzle_service.py
│       └── test_srs_service.py
│
├── Dockerfile
├── docker-compose.yml                   # 本地开发: FastAPI + Redis + Firestore Emulator
├── requirements.txt
├── .env.example
└── Makefile
```

---

## 二、数据模型与 Firestore Schema

### 2.1 牌数据常量 (34 张)

```python
# backend/app/domain/models/tile.py
from enum import Enum
from dataclasses import dataclass

class TileSuit(str, Enum):
    MAN = "man"
    PIN = "pin"
    SOU = "sou"
    WIND = "wind"
    DRAGON = "dragon"

@dataclass(frozen=True)
class TileDefinition:
    id: str           # "m1"~"m9", "p1"~"p9", "s1"~"s9", "z1"~"z7"
    suit: TileSuit
    character: str    # 汉字
    seal: str         # "萬"/"筒"/"条"/"風"/"龍"
    value: int        # 1-9 or special
    label: str        # "1-Man", "East", ...
    mnemonic: dict    # { emoji, name, slogan, desc, chinese, anchor }
    confused_with: list[str]

# 34 张牌常量 — 唯一数据源, 代码中硬编码
ALL_TILES: dict[str, TileDefinition] = { ... }  # key = tile.id

# 校验器: 所有 API 传入的 tile_id 必须在此白名单中
VALID_TILE_IDS: frozenset[str] = frozenset(ALL_TILES.keys())
```

### 2.2 Pydantic 请求/响应模型

```python
# backend/app/domain/models/puzzle.py
from pydantic import BaseModel, Field, field_validator
from app.domain.models.tile import VALID_TILE_IDS

class FlashcardAnswer(BaseModel):
    tile_id: str = Field(..., description="题目中的正确牌 ID")
    user_chose: str = Field(..., description="用户选择的牌 ID")
    response_time_ms: int = Field(..., ge=0, le=10000)

    @field_validator('tile_id', 'user_chose')
    @classmethod
    def validate_tile_id(cls, v: str) -> str:
        if v not in VALID_TILE_IDS:
            raise ValueError(f"Invalid tile ID: {v}")
        return v

class NaniKiruAnswer(BaseModel):
    puzzle_id: str
    user_discarded: str  # tile_id
    response_time_ms: int

    @field_validator('user_discarded')
    @classmethod
    def validate_discard(cls, v: str) -> str:
        if v not in VALID_TILE_IDS:
            raise ValueError(f"Invalid tile ID: {v}")
        return v

class AnswerReport(BaseModel):
    """统一答题上报模型"""
    type: str  # "flashcard" | "nanikiru"
    puzzle_id: str
    is_correct: bool
    user_answer: str
    correct_answer: str
    response_time_ms: int
    quality: int = Field(..., ge=0, le=5)  # SM-2 质量评分

class DailyQuest(BaseModel):
    date: str
    flashcards: list[dict]    # 10 道闪卡题
    nanikiru: list[dict]      # 3 道何切题
    srs_review: list[dict]    # N 道到期复习题
```

### 2.3 Firestore 文档映射

```
Collection: users/{uid}
Document:
{
  "display_name": "string",
  "email": "string",
  "created_at": "2026-06-07T00:00:00Z",
  "settings": {
    "language": "en",
    "sound_enabled": true,
    "haptic_enabled": true,
    "mnemonic_visible": true,
    "mnemonic_opacity": 1.0
  },
  "stats": {
    "total_cards_swiped": 0,
    "total_nanikiru": 0,
    "current_streak": 14,
    "longest_streak": 21,
    "elo_rating": 1248
  },
  "stamina": {
    "hearts": 3,
    "max_hearts": 3,
    "last_consumed_at": null,      // UTC timestamp
    "next_recovery_at": null        // UTC timestamp
  },
  "subscription_tier": "free",
  "subscription_expiry": null
}

Sub-collection: users/{uid}/progress/{module_id}
Document:
{
  "module": "manzu_flashcards",
  "tiles_completed": ["m1","m2","m3","m4","m5","m6","m7","m8","m9"],
  "correct_counts": {"m1": 5, "m2": 4, ...},
  "error_counts": {"m5": 3, "m8": 1, ...},
  "started_at": "2026-06-01T00:00:00Z",
  "completed_at": "2026-06-03T00:00:00Z",
  "mastery_stars": 2              // 0-3
}

Sub-collection: users/{uid}/srs_items/{item_id}
Document:
{
  "tile_id": "m5",
  "puzzle_type": "flashcard",
  "easiness_factor": 2.5,
  "interval_days": 1,
  "repetitions": 0,
  "next_review": "2026-06-08T00:00:00Z",
  "error_history": [
    {"timestamp": "...", "user_answer": "m6", "correct_answer": "m5"}
  ],
  "created_at": "2026-06-07T00:00:00Z",
  "updated_at": "2026-06-07T00:00:00Z"
}

Collection: puzzles/{puzzle_id}
Document:
{
  "type": "nanikiru",
  "difficulty_rating": 1150,       // ELO 难度分
  "content": {
    "hand_tiles": ["m1","m1","m2","m3","m3","m4","m5","m5","m6","m7","m8","m8","m9"],
    "drawn_tile": "s7",             // 刚摸到的牌
    "correct_discard": "m4"
  },
  "precomputed": {
    "m1": {"shanten": 2, "ukeire_types": ["2p"], "ukeire_count": 3, "is_correct": false},
    "m4": {"shanten": 1, "ukeire_types": ["2p","5p","8p"], "ukeire_count": 11, "is_correct": true},
    // ... 其余 12 种打法
  },
  "explanation": "Discarding 4m preserves the 567m run and opens a two-sided wait.",
  "created_by": "generator",
  "created_at": "2026-06-01T00:00:00Z"
}
```

---

## 三、API 端点实现

### 3.1 依赖注入

```python
# backend/app/api/deps.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth as firebase_auth
from google.cloud import firestore

from app.core.firebase import get_firestore
from app.core.limiter import limiter

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """验证 Firebase ID Token, 返回 decoded claims"""
    try:
        token = credentials.credentials
        decoded = firebase_auth.verify_id_token(token)
        return decoded  # { uid, email, ... }
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )

def get_db() -> firestore.Client:
    return get_firestore()
```

### 3.2 用户端点

```python
# backend/app/api/v1/user.py
from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_current_user, get_db

router = APIRouter(prefix="/user", tags=["User"])

@router.get("/profile")
async def get_profile(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """获取用户信息 + 统计数据"""
    doc = db.collection("users").document(user["uid"]).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    return doc.to_dict()

@router.patch("/settings")
async def update_settings(
    payload: dict,
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """更新用户设置 (language, sound, haptic, mnemonic_visible)"""
    allowed_keys = {"language", "sound_enabled", "haptic_enabled",
                    "mnemonic_visible", "mnemonic_opacity"}
    updates = {k: v for k, v in payload.items() if k in allowed_keys}
    if not updates:
        raise HTTPException(status_code=400, detail="No valid fields to update")
    db.collection("users").document(user["uid"]).update(updates)
    return {"status": "ok"}

@router.get("/progress")
async def get_progress(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """获取各模块通关进度"""
    docs = db.collection("users").document(user["uid"]) \
        .collection("progress").stream()
    return [{"module_id": doc.id, **doc.to_dict()} for doc in docs]

@router.post("/progress")
async def update_progress(
    payload: dict,  # { module_id, tiles_completed, error_counts, mastery_stars }
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """上报模块进度 (闪卡卡包完成 / 何切关卡完成)"""
    module_id = payload["module_id"]
    db.collection("users").document(user["uid"]) \
        .collection("progress").document(module_id).set(payload, merge=True)
    return {"status": "ok"}

@router.get("/stamina")
async def get_stamina(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """获取当前体力值 + 服务端时间 (用于防篡改)"""
    from datetime import datetime, timezone
    doc = db.collection("users").document(user["uid"]).get()
    stamina = doc.to_dict().get("stamina", {})
    return {
        **stamina,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }

@router.post("/stamina/decrease")
async def decrease_stamina(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """扣减体力 (服务端计时权威)"""
    from datetime import datetime, timedelta, timezone
    doc = db.collection("users").document(user["uid"]).get()
    stamina = doc.to_dict().get("stamina", {})
    now = datetime.now(timezone.utc)

    if stamina.get("hearts", 3) <= 0:
        raise HTTPException(status_code=400, detail="No hearts remaining")

    new_hearts = stamina["hearts"] - 1
    db.collection("users").document(user["uid"]).update({
        "stamina.hearts": new_hearts,
        "stamina.last_consumed_at": now.isoformat(),
        "stamina.next_recovery_at": (
            now + timedelta(hours=4)).isoformat() if new_hearts < stamina.get("max_hearts", 3) else None,
    })
    return {
        "hearts": new_hearts,
        "next_recovery_at": (now + timedelta(hours=4)).isoformat() if new_hearts < 3 else None,
        "server_time": now.isoformat(),
    }
```

### 3.3 题库端点

```python
# backend/app/api/v1/puzzles.py
from fastapi import APIRouter, Depends, Query
from app.api.deps import get_current_user, get_db
from app.domain.services.puzzle_service import PuzzleService

router = APIRouter(prefix="/puzzles", tags=["Puzzles"])

@router.get("/daily")
async def get_daily_quest(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: PuzzleService = Depends(),
):
    """获取今日卡包: 10 闪卡 + 3 何切 + N 错题复习"""
    return await service.build_daily_quest(user["uid"], db)

@router.get("/flashcards")
async def get_flashcards(
    suite: str = Query("all", pattern="^(all|man|pin|sou|honor)$"),
    count: int = Query(10, ge=5, le=20),
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: PuzzleService = Depends(),
):
    """获取闪卡题目 (可按花色筛选)"""
    return await service.generate_flashcards(
        uid=user["uid"], suite=suite, count=count, db=db
    )

@router.get("/nanikiru")
async def get_nanikiru(
    difficulty: str = Query("beginner", pattern="^(beginner|intermediate|advanced)$"),
    count: int = Query(3, ge=1, le=10),
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: PuzzleService = Depends(),
):
    """获取何切题目 (含预计算结果)"""
    return await service.generate_nanikiru(
        uid=user["uid"], difficulty=difficulty, count=count, db=db
    )

@router.post("/evaluate")
async def evaluate_answer(
    report: dict,  # AnswerReport
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: PuzzleService = Depends(),
):
    """提交答题结果 → 更新 SRS + 进度 + 体力"""
    return await service.evaluate_answer(user["uid"], report, db)
```

### 3.4 算番端点 (付费)

```python
# backend/app/api/v1/mahjong.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from app.api.deps import get_current_user, get_db
from app.domain.models.tile import VALID_TILE_IDS
from app.engine.hand_calculator import HandCalculator

router = APIRouter(prefix="/mahjong", tags=["Mahjong Engine"])

class HandCalculateRequest(BaseModel):
    tiles: list[str]  # 14 个 tile_id
    win_tile: str | None = None  # 自摸/荣和的牌

    @field_validator('tiles')
    @classmethod
    def validate_all_tiles(cls, v: list[str]) -> list[str]:
        for tid in v:
            if tid not in VALID_TILE_IDS:
                raise ValueError(f"Invalid tile ID: {tid}")
        return v

    @field_validator('win_tile')
    @classmethod
    def validate_win_tile(cls, v: str | None) -> str | None:
        if v is not None and v not in VALID_TILE_IDS:
            raise ValueError(f"Invalid win_tile ID: {v}")
        return v

@router.post("/calculate")
async def calculate_hand(
    req: HandCalculateRequest,
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """完整算番: 14 张牌 → Yaku 列表 + Han + Fu + 点数"""
    # 检查 Pro 订阅
    user_doc = db.collection("users").document(user["uid"]).get()
    if user_doc.to_dict().get("subscription_tier") != "premium":
        raise HTTPException(status_code=403, detail="Premium subscription required")

    calculator = HandCalculator()
    result = calculator.evaluate(req.tiles, req.win_tile)

    return {
        "is_winning": result.is_agari,
        "han": result.han,
        "fu": result.fu,
        "yaku": [{"name": y.name, "han": y.han} for y in result.yaku],
        "points": result.cost.get("main", 0),
    }

@router.post("/shanten")
async def calculate_shanten(
    req: HandCalculateRequest,
    user: dict = Depends(get_current_user),
):
    """仅计算向听数 (免费)"""
    from app.engine.shanten import ShantenCalculator
    return {"shanten": ShantenCalculator(req.tiles).calculate()}

@router.post("/ukeire")
async def calculate_ukeire(
    req: HandCalculateRequest,
    user: dict = Depends(get_current_user),
):
    """计算打出某张牌后的进张数 (免费, 但仅限 MVP 预计算覆盖的牌姿)"""
    if len(req.tiles) != 14:
        raise HTTPException(status_code=400, detail="Exactly 14 tiles required")
    from app.engine.ukeire import UkeireCalculator
    return UkeireCalculator(req.tiles).calculate()
```

### 3.5 SRS 端点

```python
# backend/app/api/v1/srs.py
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user, get_db
from app.domain.services.srs_service import SrsService

router = APIRouter(prefix="/srs", tags=["SRS"])

@router.get("/review_due")
async def get_due_reviews(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: SrsService = Depends(),
):
    """获取当前到期的复习题"""
    return await service.get_due_items(user["uid"], db)

@router.post("/report")
async def report_answer(
    report: dict,  # { tile_id, puzzle_type, quality (0-5) }
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: SrsService = Depends(),
):
    """上报答题结果 → 更新 SM-2 参数"""
    return await service.update_srs_item(user["uid"], report, db)

@router.post("/sync")
async def batch_sync(
    payload: list[dict],  # 离线期间积累的 SRS 条目
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: SrsService = Depends(),
):
    """批量同步离线答题记录 → 合并 SRS 参数"""
    return await service.batch_sync(user["uid"], payload, db)

@router.get("/stats")
async def get_srs_stats(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
    service: SrsService = Depends(),
):
    """获取用户 SRS 统计数据 (弱项雷达图)"""
    return await service.get_stats(user["uid"], db)
```

### 3.6 订阅端点

```python
# backend/app/api/v1/subscription.py
from fastapi import APIRouter, Depends, Request, HTTPException
from app.api.deps import get_current_user, get_db
from app.core.revenuecat import RevenueCatClient

router = APIRouter(tags=["Subscription"])

@router.post("/subscription/verify")
async def verify_subscription(
    receipt_data: dict,  # RevenueCat purchaserInfo
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    """服务端二次验证订阅状态"""
    rc = RevenueCatClient()
    subscriber = await rc.get_subscriber(user["uid"])

    entitlements = subscriber.get("subscriber", {}).get("entitlements", {})
    pro = entitlements.get("premium", {})
    is_active = pro.get("expires_date") is not None

    if is_active:
        db.collection("users").document(user["uid"]).update({
            "subscription_tier": "premium",
            "subscription_expiry": pro.get("expires_date"),
        })

    return {"is_pro": is_active, "expires_at": pro.get("expires_date")}

@router.get("/subscription/status")
async def get_subscription_status(
    user: dict = Depends(get_current_user),
    db = Depends(get_db),
):
    doc = db.collection("users").document(user["uid"]).get()
    data = doc.to_dict()
    return {
        "tier": data.get("subscription_tier", "free"),
        "expires_at": data.get("subscription_expiry"),
    }

@router.post("/webhooks/revenuecat")
async def revenuecat_webhook(request: Request, db = Depends(get_db)):
    """RevenueCat Webhook: 订阅变更实时通知"""
    import hmac, hashlib
    from app.config import settings

    # 验证 webhook 签名
    body = await request.body()
    signature = request.headers.get("X-RevenueCat-Signature")
    expected = hmac.new(
        settings.REVENUECAT_WEBHOOK_SECRET.encode(),
        body, hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(signature or "", expected):
        raise HTTPException(status_code=401, detail="Invalid signature")

    event = await request.json()
    event_type = event.get("event_type")
    uid = event.get("event", {}).get("app_user_id")

    if event_type in ("INITIAL_PURCHASE", "RENEWAL", "NON_RENEWING_PURCHASE"):
        db.collection("users").document(uid).update({
            "subscription_tier": "premium",
            "subscription_expiry": event.get("event", {}).get("expiration_at_ms"),
        })
    elif event_type in ("CANCELLATION", "EXPIRATION"):
        db.collection("users").document(uid).update({
            "subscription_tier": "free",
            "subscription_expiry": None,
        })

    return {"status": "ok"}
```

---

## 四、麻将引擎集成

### 4.1 向听数计算器

```python
# backend/app/engine/shanten.py
class ShantenCalculator:
    """
    向听数计算 — 日麻标准算法

    手牌表示: 34 维数组, 索引 0-8=万, 9-17=饼, 18-26=条, 27-33=字
    """

    def __init__(self, tiles: list[str]):
        self.tiles34 = self._to_34_array(tiles)
        self._best = 999

    @staticmethod
    def _to_34_array(tile_ids: list[str]) -> list[int]:
        """将 tile_id 列表转为 34 维数组"""
        arr = [0] * 34
        INDEX_MAP = {
            f"m{i}": i-1 for i in range(1, 10)
        } | {
            f"p{i}": 8 + i for i in range(1, 10)
        } | {
            f"s{i}": 17 + i for i in range(1, 10)
        } | {
            "z1": 27, "z2": 28, "z3": 29, "z4": 30,  # 东南西北
            "z5": 31, "z6": 32, "z7": 33,              # 白发中
        }
        for tid in tile_ids:
            arr[INDEX_MAP[tid]] += 1
        return arr

    def calculate(self) -> int:
        """返回最小向听数 (0=听牌, 1=1向听...)"""
        # 1. 七对子向听
        chiitoi = 6 - sum(1 for c in self.tiles34 if c >= 2)
        self._best = min(self._best, chiitoi)

        # 2. 国士无双向听
        kokushi = self._kokushi_shanten()
        self._best = min(self._best, kokushi)

        # 3. 标准 4面子+1雀头 向听
        self._search_melds(4, 1, 0)
        return self._best

    def _kokushi_shanten(self) -> int:
        """国士无双向听数: 13 么九牌 — 已有种数 — 对子修正"""
        terminals = [0,8,9,17,18,26] + list(range(27,34))
        has_pair = any(self.tiles34[i] >= 2 for i in terminals)
        kinds = sum(1 for i in terminals if self.tiles34[i] > 0)
        return 13 - kinds - (0 if has_pair else 1)

    def _search_melds(self, mentsu: int, jantou: int, start: int):
        """回溯搜索面子+雀头组合, 更新 _best"""
        # 剪枝
        current_shanten = (4 - mentsu) * 2 - (1 - jantou) + self._count_partials()
        if current_shanten >= self._best:
            return
        # 递归搜索顺子/刻子/对子
        # ... (标准回溯实现, 约 80 行)
```

### 4.2 完整手牌估值 (封装 mahjong 库)

```python
# backend/app/engine/hand_calculator.py
from dataclasses import dataclass
from mahjong.hand_calculating.hand import HandCalculator as MJHandCalculator
from mahjong.tile import TilesConverter
from mahjong.hand_calculating.hand_config import HandConfig
from mahjong.meld import Meld

@dataclass
class HandResult:
    is_agari: bool
    han: int
    fu: int
    yaku: list
    cost: dict

class HandCalculator:
    """封装 mahjong-py 库的日麻手牌估值器"""

    def __init__(self):
        self._calc = MJHandCalculator()

    def evaluate(
        self,
        tiles: list[str],
        win_tile: str | None = None,
        is_tsumo: bool = False,
        dora_indicators: list[str] | None = None,
    ) -> HandResult:
        """评估 14 张牌的胡牌情况"""
        # 转换: tile_id[] → 34维数组 → mahjong 库的 136维格式
        tiles_34 = [0] * 34
        for tid in tiles:
            tiles_34[self._idx(tid)] += 1

        tiles_136 = TilesConverter.string_to_136_array(
            man=''.join(str(i+1) * tiles_34[i] for i in range(9)),
            pin=''.join(str(i+1) * tiles_34[i+9] for i in range(9)),
            sou=''.join(str(i+1) * tiles_34[i+18] for i in range(9)),
            honors=''.join(str(i+1) * tiles_34[i+27] for i in range(7)),
            has_man=True, has_pin=True, has_sou=True, has_honors=True,
        )

        win_tile_136 = None
        if win_tile:
            w34 = [0] * 34
            w34[self._idx(win_tile)] = 1
            win_tile_136 = TilesConverter.string_to_136_array(
                man=''.join(str(i+1) * w34[i] for i in range(9)),
                pin=''.join(str(i+1) * w34[i+9] for i in range(9)),
                sou=''.join(str(i+1) * w34[i+18] for i in range(9)),
                honors=''.join(str(i+1) * w34[i+27] for i in range(7)),
                has_man=True, has_pin=True, has_sou=True, has_honors=True,
            )[0]

        result = self._calc.estimate_hand_value(
            tiles_136,
            win_tile_136 if win_tile_136 else tiles_136[-1],
            config=HandConfig(is_tsumo=is_tsumo),
        )

        return HandResult(
            is_agari=result.error is None,
            han=result.han or 0,
            fu=result.fu or 0,
            yaku=[{"name": y.name, "han": y.han} for y in (result.yaku or [])],
            cost=result.cost or {},
        )

    @staticmethod
    def _idx(tile_id: str) -> int:
        """tile_id → 34维数组索引"""
        suit, num = tile_id[0], tile_id[1:]
        if suit == 'm': return int(num) - 1
        if suit == 'p': return 8 + int(num)
        if suit == 's': return 17 + int(num)
        if suit == 'z': return 26 + int(num)
        raise ValueError(f"Unknown tile: {tile_id}")
```

### 4.3 进张数计算器

```python
# backend/app/engine/ukeire.py
class UkeireCalculator:
    """
    进张数 (Ukeire) 计算器
    对于给定 14 张牌, 计算打出每张牌后的进张
    """

    def __init__(self, tiles: list[str]):
        self.tiles = tiles

    def calculate(self) -> dict[str, dict]:
        """
        返回: {
           "m4": { "shanten_after": 1, "ukeire_types": ["2p","5p","8p"], "ukeire_count": 11 },
           "m5": { "shanten_after": 2, "ukeire_types": ["4p"], "ukeire_count": 4 },
           ...
         }
        """
        results = {}
        # 去重: 相同 tile_id 的牌只计算一次
        seen = set()
        for i, discard_id in enumerate(self.tiles):
            if discard_id in seen:
                continue
            seen.add(discard_id)

            remaining = self.tiles[:i] + self.tiles[i+1:]  # 13 张 (去掉打出的)
            ukeire_types = []
            ukeire_count = 0

            # 尝试摸入 34 种牌的每一种
            for test_id in ALL_TILE_IDS:
                candidate = remaining + [test_id]  # 14 张 (模拟摸入)
                shanten = ShantenCalculator(candidate).calculate()
                if shanten < ShantenCalculator(self.tiles).calculate():
                    ukeire_types.append(test_id)
                    ukeire_count += 4 - self.tiles.count(test_id)  # 还剩余的枚数

            results[discard_id] = {
                "shanten_after": ShantenCalculator(remaining).calculate(),
                "ukeire_types": ukeire_types,
                "ukeire_count": ukeire_count,
            }

        return results
```

---

## 五、题库生成 Pipeline

### 5.1 PuzzleService

```python
# backend/app/domain/services/puzzle_service.py
import random
from datetime import datetime, timezone
from google.cloud import firestore

class PuzzleService:
    async def build_daily_quest(self, uid: str, db: firestore.Client) -> dict:
        """组装每日任务: 闪卡 + 何切 + SRS 复习"""
        user_doc = db.collection("users").document(uid).get()
        elo = user_doc.to_dict().get("stats", {}).get("elo_rating", 1000)

        # 1. 获取到期的 SRS 复习题
        srs_review = await self._get_due_srs(uid, db)

        # 2. 生成新闪卡 (排除已完成的 tile)
        new_flashcards = await self.generate_flashcards(
            uid=uid, suite="all",
            count=max(0, 10 - len(srs_review)),
            db=db
        )

        # 3. 生成何切题
        nanikiru = await self.generate_nanikiru(
            uid=uid, difficulty=self._elo_to_difficulty(elo),
            count=3, db=db
        )

        return {
            "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "flashcards": srs_review + new_flashcards,
            "nanikiru": nanikiru,
            "srs_review": srs_review,
        }

    async def generate_flashcards(
        self, uid: str, suite: str, count: int, db: firestore.Client
    ) -> list[dict]:
        """生成闪卡题目: 4 选 1 格式, 优先选择易混淆牌作为干扰项"""
        completed = await self._get_completed_tiles(uid, db)
        candidates = [
            t for t in ALL_TILES.values()
            if t.id not in completed and (suite == "all" or self._match_suite(t, suite))
        ]
        selected = random.sample(candidates, min(count, len(candidates)))

        result = []
        for tile in selected:
            distractors = random.sample(
                [t for t in ALL_TILES.values() if t.id != tile.id],
                3
            )
            options = random.sample([tile] + distractors, 4)
            result.append({
                "tile_id": tile.id,
                "correct_id": tile.id,
                "options": [
                    {"id": o.id, "label": o.label, "emoji": o.mnemonic["emoji"],
                     "name": o.mnemonic["name"]}
                    for o in options
                ],
                "mnemonic": tile.mnemonic,
            })

        return result

    async def generate_nanikiru(
        self, uid: str, difficulty: str, count: int, db: firestore.Client
    ) -> list[dict]:
        """从题库中按 ELO 难度匹配合适的何切题"""
        elo = await self._get_user_elo(uid, db)
        elo_range = {
            "beginner": (800, 1200),
            "intermediate": (1100, 1500),
            "advanced": (1400, 1800),
        }.get(difficulty, (800, 1200))

        puzzles = db.collection("puzzles") \
            .where("type", "==", "nanikiru") \
            .where("difficulty_rating", ">=", elo_range[0]) \
            .where("difficulty_rating", "<=", elo_range[1]) \
            .limit(count * 3).stream()

        selected = random.sample(list(puzzles), min(count, len(list(puzzles))))
        return [{"puzzle_id": doc.id, **doc.to_dict()} for doc in selected]

    @staticmethod
    def _elo_to_difficulty(elo: int) -> str:
        if elo < 1100: return "beginner"
        if elo < 1400: return "intermediate"
        return "advanced"
```

### 5.2 Celery 题库生成任务

```python
# backend/app/workers/puzzle_generator.py
from celery import Celery
from app.engine.ukeire import UkeireCalculator
from app.engine.shanten import ShantenCalculator

celery_app = Celery('tilezhan', broker='redis://localhost:6379/0')

@celery_app.task
def generate_nanikiru_batch(
    hand_templates: list[list[str]],
    batch_size: int = 100,
):
    """
    批量生成何切题目 + 预计算结果

    hand_templates: 来自手动录入或爬虫 Pipeline 的手牌模板
    """
    from app.core.firebase import get_firestore
    db = get_firestore()
    batch = db.batch()

    for i, hand in enumerate(hand_templates[:batch_size]):
        # 计算每种舍牌的结果
        ukeire_results = UkeireCalculator(hand).calculate()

        # 找最优解
        best_discard = max(
            ukeire_results,
            key=lambda t: ukeire_results[t]["ukeire_count"]
        )

        # 计算难度
        shanten_before = ShantenCalculator(hand).calculate()
        correct_count = sum(
            1 for r in ukeire_results.values()
            if r["ukeire_count"] >= ukeire_results[best_discard]["ukeire_count"]
        )
        difficulty = 800 + int(shanten_before * 200) + (14 - correct_count) * 50

        puzzle_ref = db.collection("puzzles").document()
        batch.set(puzzle_ref, {
            "type": "nanikiru",
            "difficulty_rating": difficulty,
            "content": {
                "hand_tiles": hand,
                "drawn_tile": hand[-1],
                "correct_discard": best_discard,
            },
            "precomputed": {
                tid: {
                    "shanten_after": r["shanten_after"],
                    "ukeire_types": r["ukeire_types"],
                    "ukeire_count": r["ukeire_count"],
                    "is_correct": tid == best_discard,
                }
                for tid, r in ukeire_results.items()
            },
            "created_by": "batch_generator",
            "created_at": firestore.SERVER_TIMESTAMP,
        })

        if i % 500 == 0:
            batch.commit()
            batch = db.batch()

    batch.commit()
    return {"generated": min(len(hand_templates), batch_size)}
```

---

## 六、SRS 后端服务

### 6.1 SrsService (单条更新)

```python
# backend/app/domain/services/srs_service.py
from datetime import datetime, timezone
from google.cloud import firestore

class SrsService:
    async def get_due_items(self, uid: str, db: firestore.Client) -> list[dict]:
        """获取到期复习题"""
        now = datetime.now(timezone.utc)
        docs = db.collection("users").document(uid) \
            .collection("srs_items") \
            .where("next_review", "<=", now) \
            .order_by("easiness_factor") \
            .limit(20).stream()

        items = []
        for doc in docs:
            data = doc.to_dict()
            tile = ALL_TILES.get(data["tile_id"])
            if tile:
                items.append({
                    "srs_item_id": doc.id,
                    "tile_id": data["tile_id"],
                    "mnemonic": tile.mnemonic,
                    "error_count": len(data.get("error_history", [])),
                    "next_review": data["next_review"].isoformat(),
                })
        return items

    async def update_srs_item(
        self, uid: str, report: dict, db: firestore.Client
    ) -> dict:
        """根据答题结果更新 SM-2 参数"""
        tile_id = report["tile_id"]
        quality = report["quality"]  # 0-5

        # 查找已有 SRS 条目或创建新的
        existing = list(db.collection("users").document(uid)
            .collection("srs_items")
            .where("tile_id", "==", tile_id)
            .limit(1).stream())

        if existing:
            doc_ref = existing[0].reference
            data = existing[0].to_dict()
            ef = data["easiness_factor"]
            reps = data["repetitions"]
            interval = data["interval_days"]
        else:
            doc_ref = db.collection("users").document(uid) \
                .collection("srs_items").document()
            ef, reps, interval = 2.5, 0, 1

        # SM-2 计算
        if quality < 3:
            new_ef, new_reps, new_interval = ef, 0, 1
        else:
            new_ef = max(1.3, ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
            new_reps = reps + 1
            new_interval = 1 if new_reps == 1 else 6 if new_reps == 2 else round(interval * new_ef)

        now = datetime.now(timezone.utc)
        next_review = now.replace(hour=2, minute=0, second=0)
        if next_review < now:
            from datetime import timedelta
            next_review = (now + timedelta(days=new_interval)).replace(
                hour=2, minute=0, second=0
            )

        doc_ref.set({
            "tile_id": tile_id,
            "puzzle_type": report.get("puzzle_type", "flashcard"),
            "easiness_factor": new_ef,
            "interval_days": new_interval,
            "repetitions": new_reps,
            "next_review": next_review,
            "updated_at": now,
        }, merge=True)

        return {
            "tile_id": tile_id,
            "easiness_factor": new_ef,
            "interval_days": new_interval,
            "repetitions": new_reps,
            "next_review": next_review.isoformat(),
        }

    async def batch_sync(
        self, uid: str, items: list[dict], db: firestore.Client
    ) -> dict:
        """批量同步离线 SRS 条目 — Last-Write-Wins"""
        updated = 0
        for item in items:
            existing = list(db.collection("users").document(uid)
                .collection("srs_items")
                .where("tile_id", "==", item["tile_id"])
                .limit(1).stream())

            if existing:
                remote = existing[0].to_dict()
                # LWW: 比较时间戳
                if item.get("updated_at", "") > remote.get("updated_at", ""):
                    existing[0].reference.set(item, merge=True)
                    updated += 1
            else:
                doc_ref = db.collection("users").document(uid) \
                    .collection("srs_items").document()
                doc_ref.set(item)
                updated += 1

        return {"synced": updated}

    async def get_stats(self, uid: str, db: firestore.Client) -> dict:
        """弱项雷达图数据: 按花色统计错误率"""
        docs = db.collection("users").document(uid) \
            .collection("srs_items").stream()

        stats = {"man": 0, "pin": 0, "sou": 0, "honor": 0, "total": 0}
        for doc in docs:
            data = doc.to_dict()
            tile = ALL_TILES.get(data["tile_id"])
            if not tile:
                continue
            suit_key = tile.suit.value if tile.suit.value in ("man","pin","sou") else "honor"
            stats[suit_key] += 1
            stats["total"] += 1

        return stats
```

### 6.2 批量同步 (Batch Sync with LWW)

```python
# backend/app/domain/services/sync_service.py
class SyncService:
    async def process_sync(self, uid: str, operations: list[dict], db) -> dict:
        """使用 Firestore batch writes 批量同步离线 SRS 记录。
        LWW: client_timestamp >= server updated_at 才允许写入。"""
        batch = db.batch()
        applied = 0
        for op in operations:
            doc = await doc_ref.get()
            if doc.exists:
                if op["client_timestamp"] < doc.to_dict().get("updated_at", 0):
                    continue  # 客户端数据过期
                ef, reps, interval = doc.to_dict()["easiness_factor"], ...
            else:
                ef, reps, interval = 2.5, 0, 0
            new_ef, new_reps, new_interval = self._sm2(ef, reps, interval, op["quality"])
            batch.set(doc_ref, {..., "updated_at": op["client_timestamp"]}, merge=True)
            applied += 1
        await batch.commit()
        return {"synced": applied}
```

**关键优化**:
- 使用 `db.batch()` 替代逐个 `set()`，减少 N+1 I/O
- 幂等性基于 `updated_at`，重复请求不会叠加

---

## 七、RevenueCat Webhook

完整实现在 §3.6，补充 RevenueCatClient 封装：

```python
# backend/app/core/revenuecat.py
import httpx
from app.config import settings

class RevenueCatClient:
    BASE_URL = "https://api.revenuecat.com/v1"

    def __init__(self):
        self._client = httpx.AsyncClient(
            base_url=self.BASE_URL,
            headers={
                "Authorization": f"Bearer {settings.REVENUECAT_API_KEY}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            timeout=10.0,
        )

    async def get_subscriber(self, app_user_id: str) -> dict:
        """获取用户订阅信息"""
        response = await self._client.get(
            f"/subscribers/{app_user_id}"
        )
        response.raise_for_status()
        return response.json()

    async def close(self):
        await self._client.aclose()
```

---

## 八、安全中间件

### 8.1 Rate Limiter

```python
# backend/app/core/limiter.py
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

# 使用: 在端点装饰器上
# @router.post("/evaluate")
# @limiter.limit("100/minute")
```

### 8.2 Firebase Auth 中间件

```python
# backend/app/core/security.py
from firebase_admin import auth as firebase_auth
from fastapi import HTTPException, status

async def verify_firebase_token(token: str) -> dict:
    """验证 Firebase ID Token"""
    try:
        return firebase_auth.verify_id_token(token, check_revoked=True)
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Token expired")
    except firebase_auth.RevokedIdTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Token revoked")
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Invalid token")
```

### 8.3 输入验证工具

```python
# backend/app/domain/validators/tile_validator.py
from app.domain.models.tile import VALID_TILE_IDS

def validate_tile_ids(tile_ids: list[str]) -> None:
    """校验所有 tile_id 在白名单内"""
    invalid = [tid for tid in tile_ids if tid not in VALID_TILE_IDS]
    if invalid:
        raise ValueError(f"Invalid tile IDs: {invalid}")

def validate_hand_size(tile_ids: list[str], expected: int = 14) -> None:
    """校验手牌数量"""
    if len(tile_ids) != expected:
        raise ValueError(
            f"Expected {expected} tiles, got {len(tile_ids)}"
        )
```

### 8.4 NTP 防篡改 (服务端时间校验)

**威胁**: 用户修改手机本地时间绕过体力恢复（4h/❤️）。

**对策**: 服务端校验客户端提交的 `client_timestamp` 与服务器 UTC 时间偏差。

```python
# backend/app/core/ntp_guard.py
from datetime import datetime, timedelta, timezone

MAX_DEVIATION_SECONDS = 300  # 5 分钟

def validate_client_timestamp(client_timestamp_ms: int) -> None:
    server_now = datetime.now(timezone.utc)
    client_time = datetime.fromtimestamp(client_timestamp_ms / 1000, tz=timezone.utc)
    deviation = abs((server_now - client_time).total_seconds())
    if deviation > MAX_DEVIATION_SECONDS:
        raise TimestampTampered()
```

**体力消费端点** (`POST /user/stamina/consume`) 必须携带 `client_timestamp`:

```python
@router.post("/stamina/consume")
async def consume_stamina(payload: dict, user: dict = Depends(get_current_user)):
    validate_client_timestamp(payload.get("client_timestamp", 0))
    # ... 扣减逻辑
```

### 8.5 幂等性校验 (Idempotency)

**威胁**: 弱网环境下前端可能重复提交同一请求，导致体力多次扣减或进度重复叠加。

**对策**: 所有 POST/PATCH 端点基于 `updated_at` 做 LWW (Last-Write-Wins)。

```python
# backend/app/core/idempotency.py
def check_idempotency(client_updated_at: int, server_updated_at: int) -> bool:
    """客户端数据版本 ≥ 服务端版本 → 允许写入"""
    return client_updated_at >= server_updated_at
```

**SRS 同步中的应用**:

```python
# backend/app/domain/services/sync_service.py
class SyncService:
    async def process_sync(self, uid: str, operations: list[dict], db) -> dict:
        batch = db.batch()  # Firestore 批量写入
        applied = 0

        for op in operations:
            doc = await doc_ref.get()
            if doc.exists:
                server_ts = doc.to_dict().get("updated_at", 0)
                if not check_idempotency(op["client_timestamp"], server_ts):
                    continue  # 客户端数据过期，丢弃
                ef, reps, interval = doc.to_dict()["easiness_factor"], ...
            else:
                ef, reps, interval = 2.5, 0, 0

            # SM-2 更新参数
            new_ef, new_reps, new_interval = self._sm2(ef, reps, interval, op["quality"])
            batch.set(doc_ref, {...}, merge=True)
            applied += 1

        await batch.commit()
        return {"synced": applied}
```

### 8.6 全局异常处理

```python
# backend/app/core/exceptions.py
class AppError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code

class StaleDataError(AppError):
    def __init__(self): super().__init__("Data is stale. Refresh and retry.", 409)

class TimestampTampered(AppError):
    def __init__(self): super().__init__("Client timestamp deviates from server time", 400)

class InsufficientStamina(AppError):
    def __init__(self): super().__init__("No hearts remaining", 400)
```

在 `main.py` 注册: `app.add_exception_handler(AppError, app_error_handler)`

---

### 9.1 Firestore 复合索引配置

> 部署前必须执行: `firebase deploy --only firestore:indexes`，否则 SRS 到期查询和题库难度筛选会报错。

```json
{
  "indexes": [
    {
      "collectionGroup": "srs_items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "next_review", "order": "ASCENDING"},
        {"fieldPath": "easiness_factor", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "puzzles",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "type", "order": "ASCENDING"},
        {"fieldPath": "difficulty_rating", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "srs_items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "tile_id", "order": "ASCENDING"}
      ]
    }
  ]
}
```

### 9.2 docker-compose.yml (本地开发)

```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - REDIS_URL=redis://redis:6379/0
      - FIRESTORE_EMULATOR_HOST=firestore:8080
    volumes:
      - ./app:/app/app
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  firestore:
    image: google/cloud-sdk:emulators
    command: gcloud beta emulators firestore start --host-port=0.0.0.0:8080
    ports:
      - "8080:8080"

  celery:
    build: .
    environment:
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - ./app:/app/app
    command: celery -A app.workers.celery_app worker --loglevel=info
```

### 9.3 Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# 系统依赖 (mahjong 库需要 C++ 编译环境)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ make \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 十、测试策略

### 10.1 测试金字塔

```
         ┌──────┐
         │ E2E  │ 5%   — tests/test_e2e/ (完整 API 流程)
         ├──────┤
         │ API  │ 20%  — tests/test_api/ (端点集成测试)
         ├──────┤
         │ Unit │ 75%  — tests/test_engine/ + test_services/
         └──────┘
```

### 10.2 关键测试用例

| 类别 | 测试项 | 文件 |
|---|---|---|
| **Unit** | ShantenCalc: 听牌返回 0 | `test_engine/test_shanten.py::test_tenpai` |
| **Unit** | ShantenCalc: 国士无双 13 面 返回 0 | `test_engine/test_shanten.py::test_kokushi_13_way` |
| **Unit** | ShantenCalc: 纯九莲宝灯 返回 0 | `test_engine/test_shanten.py::test_chuuren` |
| **Unit** | UkeireCalc: 标准两面听返回正确进张 | `test_engine/test_ukeire.py::test_two_sided_wait` |
| **Unit** | HandCalc: 断幺九+平和 判定 | `test_engine/test_hand_calc.py::test_tanyao_pinfu` |
| **Unit** | SM-2: quality=5 → interval 递增 | `test_services/test_srs.py::test_sm2_perfect_recall` |
| **Unit** | SM-2: quality=1 → reset to day 1 | `test_services/test_srs.py::test_sm2_forget` |
| **Unit** | Tile Validator: 非法 ID 抛出 ValueError | `test_validators/test_tile.py::test_invalid_id` |
| **API** | GET /puzzles/daily → 200 + 含 flashcards/nanikiru/srs | `test_api/test_puzzles.py::test_daily_quest` |
| **API** | POST /mahjong/calculate (Pro) → 完整 Yaku 列表 | `test_api/test_mahjong.py::test_calculate_pro` |
| **API** | POST /mahjong/calculate (Free) → 403 | `test_api/test_mahjong.py::test_calculate_free_denied` |
| **API** | POST /subscription/webhook → 签名验证 | `test_api/test_subscription.py::test_webhook_signature` |
| **API** | POST /srs/report → SM-2 参数更新 | `test_api/test_srs.py::test_report_update` |

### 10.3 引擎测试示例

```python
# backend/tests/test_engine/test_shanten.py
import pytest
from app.engine.shanten import ShantenCalculator

class TestShanten:
    @pytest.mark.parametrize("hand,expected", [
        # 听牌 (Shanten 0)
        (["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"], 0),
        # 1 向听
        (["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","z1","z2","z3"], 1),
        # 七对子听牌 (6 对 = Shanten 0)
        (["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","p3","s1","s1"], 0),
    ])
    def test_shanten_value(self, hand, expected):
        assert ShantenCalculator(hand).calculate() == expected

    def test_shanten_consistency(self):
        """同一手牌多次计算应返回相同结果"""
        hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
        results = [ShantenCalculator(hand).calculate() for _ in range(10)]
        assert len(set(results)) == 1  # 所有结果一致
```

### 10.4 API 测试示例

```python
# backend/tests/test_api/test_puzzles.py
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_daily_quest_structure(auth_headers):
    """验证每日任务返回结构正确"""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get(
            "/api/v1/puzzles/daily",
            headers=auth_headers,
        )
    assert response.status_code == 200
    data = response.json()
    assert "flashcards" in data
    assert "nanikiru" in data
    assert "srs_review" in data
    assert len(data["nanikiru"]) == 3
    # 验证每道何切题含预计算结果
    for puzzle in data["nanikiru"]:
        assert "precomputed" in puzzle
        assert puzzle["content"]["correct_discard"] in puzzle["precomputed"]
```

---

## 十一、部署配置

### 11.1 Cloud Run 配置

```yaml
# cloudbuild.yaml (GCP Cloud Build)
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/tilezhan-api', '.']

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/tilezhan-api']

  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    args:
      - 'run'
      - 'deploy'
      - 'tilezhan-api'
      - '--image=gcr.io/$PROJECT_ID/tilezhan-api'
      - '--region=us-central1'
      - '--platform=managed'
      - '--memory=512Mi'
      - '--cpu=1'
      - '--min-instances=0'
      - '--max-instances=10'
      - '--concurrency=80'
      - '--allow-unauthenticated'
      - '--set-env-vars=REDIS_URL=redis://...'
```

### 11.2 环境变量清单

```bash
# .env.example — 本地开发
FIREBASE_PROJECT_ID=tilezhan-dev
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@tilezhan-dev.iam.gserviceaccount.com
FIRESTORE_EMULATOR_HOST=localhost:8080  # 本地开发时使用模拟器

REVENUECAT_API_KEY=rck_test_...
REVENUECAT_WEBHOOK_SECRET=whsec_...

REDIS_URL=redis://localhost:6379/0
RATE_LIMIT_PER_MINUTE=100
DEBUG=true
```

---

> 📐 本文档面向 Python 后端工程师。覆盖 API 实现、引擎集成、数据模型、SRS 服务、安全、测试、部署全维度。配合 `tilezhan-architecture.md` (CTO 视角) 和 `tilezhan-frontend-design.md` (前端视角) 阅读。
> 修订: v1.1 (2026-06-07) — 新增 §6.2 批量同步, §8.4 NTP, §8.5 幂等, §8.6 异常处理, §9.1 复合索引。
