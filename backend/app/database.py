"""
PAW — Conexión a la base de datos con SQLAlchemy 2.0 async.
Provee el engine, la session factory y la Base declarativa.
"""

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.config import get_settings

settings = get_settings()

# Engine async con pool optimizado para MVP
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,  # Loguea SQL en desarrollo
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,  # Detecta conexiones muertas
)

# Factory de sesiones async
async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """Clase base para todos los modelos SQLAlchemy del proyecto."""

    pass


async def get_db() -> AsyncSession:
    """
    Dependency de FastAPI para inyectar sesiones de BD.
    Los routers manejan sus propios commit/rollback.
    Uso: db: AsyncSession = Depends(get_db)
    """
    async with async_session() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
