"""RevenueCat product definitions — single source of truth."""

PRODUCTS = {
    "tilezhan_premium_monthly": {
        "type": "subscription",
        "price": 4.99,
        "currency": "USD",
        "period": "P1M",
        "title": "TileZhan Pro Monthly",
        "description": "Unlimited hearts, all mnemonic illustrations, advanced puzzles",
    },
    "tilezhan_premium_yearly": {
        "type": "subscription",
        "price": 29.99,
        "currency": "USD",
        "period": "P1Y",
        "title": "TileZhan Pro Yearly",
        "description": "50% off vs monthly — best value for dedicated learners",
    },
}

ENTITLEMENT_MAP = {
    "tilezhan_premium_monthly": "premium",
    "tilezhan_premium_yearly": "premium",
}
