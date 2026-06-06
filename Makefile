.PHONY: backend-install backend-test backend-run backend-lint frontend-run clean

# ── Backend ──
backend-install:
	cd backend && pip install -r requirements.txt

backend-test:
	cd backend && python -m pytest tests/ -v

backend-test-quick:
	cd backend && python -m pytest tests/ -q

backend-run:
	cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

backend-lint:
	cd backend && python -m ruff check app/

# ── Frontend ──
frontend-install:
	cd frontend && flutter pub get

frontend-run:
	cd frontend && flutter run

frontend-test:
	cd frontend && flutter test

frontend-analyze:
	cd frontend && flutter analyze

# ── All ──
test-all: backend-test-quick
	cd frontend && flutter test

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	cd frontend && flutter clean
