"""Create Firestore composite indexes via Admin SDK."""

import os

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.expanduser(
    "~/.firebase-sa.json"
)

from google.cloud.firestore_admin_v1 import FirestoreAdminClient
from google.cloud.firestore_admin_v1.types import Index, field

client = FirestoreAdminClient()
parent = "projects/tilezhan-ac3b8/databases/(default)/collectionGroups"

indexes = [
    # SRS items: next_review ASC + easiness_factor ASC
    {
        "group": "srs_items",
        "fields": [
            ("next_review", Index.IndexField.Order.ASCENDING),
            ("easiness_factor", Index.IndexField.Order.ASCENDING),
        ],
    },
    # Puzzles: type ASC + difficulty_rating ASC
    {
        "group": "puzzles",
        "fields": [
            ("type", Index.IndexField.Order.ASCENDING),
            ("difficulty_rating", Index.IndexField.Order.ASCENDING),
        ],
    },
]

for idx_def in indexes:
    idx = Index(
        query_scope=Index.QueryScope.COLLECTION,
        fields=[
            field.Field(field_path=fp, order=order)
            for fp, order in idx_def["fields"]
        ],
    )
    name = f"{parent}/{idx_def['group']}/indexes"
    try:
        op = client.create_index(parent=name, index=idx)
        print(f"Creating index on {idx_def['group']}: {op.result().name}")
    except Exception as e:
        if "already exists" in str(e).lower():
            print(f"Index on {idx_def['group']} already exists")
        else:
            print(f"Error on {idx_def['group']}: {e}")

print("Done")
