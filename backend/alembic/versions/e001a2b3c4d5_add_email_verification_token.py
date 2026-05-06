"""add email verification token

Revision ID: e001a2b3c4d5
Revises: 9f10408339ee
Create Date: 2026-05-05
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'e001a2b3c4d5'
down_revision: Union[str, None] = '9f10408339ee'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('email_verification_token', sa.String(8), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'email_verification_token')
