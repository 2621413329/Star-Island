"""mood island styles and richer companion visual schema

Revision ID: 202606010004
Revises: 202606010003
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202606010004"
down_revision: str | None = "202606010003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

DEFAULT_STYLES = [
    ("happy", "sunny_beach", {"label": "晴朗沙滩岛", "sky_top": "#FFF8ED", "sky_bottom": "#FFEFD4", "sea": "#4FC3F7", "sand": "#FFE0B2", "accent": "#FFD54F", "wave_intensity": 0.6, "rain": False, "wind": False}),
    ("calm", "soft_beach", {"label": "温柔海湾岛", "sky_top": "#F2FAF7", "sky_bottom": "#E3F4EE", "sea": "#81D4FA", "sand": "#FFF3E0", "accent": "#A8DFCF", "wave_intensity": 0.35, "rain": False, "wind": False}),
    ("thinking", "misty_beach", {"label": "静静海湾岛", "sky_top": "#ECEFF1", "sky_bottom": "#CFD8DC", "sea": "#90A4AE", "sand": "#ECEFF1", "accent": "#B0BEC5", "wave_intensity": 0.25, "rain": False, "wind": False}),
    ("sad", "drizzle_beach", {"label": "细雨沙滩岛", "sky_top": "#90A4AE", "sky_bottom": "#CFD8DC", "sea": "#607D8B", "sand": "#D7CCC8", "accent": "#90A4AE", "wave_intensity": 0.45, "rain": True, "wind": False}),
    ("angry", "windy_beach", {"label": "微风海岸岛", "sky_top": "#FFCCBC", "sky_bottom": "#FFE0B2", "sea": "#4DD0E1", "sand": "#FFCCBC", "accent": "#FF8A65", "wave_intensity": 0.75, "rain": False, "wind": True}),
]


def upgrade() -> None:
    op.create_table(
        "mood_island_styles",
        sa.Column("mood_id", sa.String(32), primary_key=True),
        sa.Column("style_key", sa.String(64), nullable=False),
        sa.Column("config", postgresql.JSONB(), nullable=False),
        sa.Column("version", sa.String(16), server_default="v1", nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    table = sa.table(
        "mood_island_styles",
        sa.column("mood_id", sa.String),
        sa.column("style_key", sa.String),
        sa.column("config", postgresql.JSONB),
    )
    op.bulk_insert(table, [{"mood_id": m, "style_key": k, "config": c} for m, k, c in DEFAULT_STYLES])


def downgrade() -> None:
    op.drop_table("mood_island_styles")
