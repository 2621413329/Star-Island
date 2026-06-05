"""add mood island biome configuration

Revision ID: 202606010005
Revises: 202606010004
"""

from collections.abc import Sequence
import json

import sqlalchemy as sa
from alembic import op

revision: str = "202606010005"
down_revision: str | None = "202606010004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

BIOME_PATCHES = {
    "happy": {
        "grass": "#BCEB63",
        "flower": "#FFF176",
        "island_shape": "heart",
        "biome": "sunny",
        "ambient_particles": "sparkle",
    },
    "calm": {
        "grass": "#A8DF9A",
        "flower": "#F8BBD0",
        "island_shape": "heart",
        "biome": "soft",
        "ambient_particles": "sparkle",
    },
    "thinking": {
        "grass": "#A5B7A0",
        "flower": "#E1BEE7",
        "island_shape": "heart",
        "biome": "mist",
        "ambient_particles": "fireflies",
    },
    "sad": {
        "grass": "#9CCCBC",
        "flower": "#B3E5FC",
        "island_shape": "heart",
        "biome": "drizzle",
        "ambient_particles": "drizzle",
    },
    "angry": {
        "grass": "#C7A66A",
        "flower": "#FFAB91",
        "island_shape": "heart",
        "biome": "windy",
        "ambient_particles": "leaves",
    },
}


def upgrade() -> None:
    bind = op.get_bind()
    for mood_id, patch in BIOME_PATCHES.items():
        bind.execute(
            sa.text(
                "UPDATE mood_island_styles "
                "SET config = config || CAST(:patch AS jsonb), version = 'v2' "
                "WHERE mood_id = :mood_id"
            ),
            {"patch": json.dumps(patch), "mood_id": mood_id},
        )


def downgrade() -> None:
    keys = " - 'grass' - 'flower' - 'island_shape' - 'biome' - 'ambient_particles'"
    op.execute(f"UPDATE mood_island_styles SET config = config {keys}, version = 'v1'")
