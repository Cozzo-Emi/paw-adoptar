from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.database import engine

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Backend para PAW - App de Adopción de Mascotas",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint to verify API status"""
    return {
        "status": "ok",
        "app_name": settings.app_name,
        "environment": settings.app_env
    }

from app.auth.router import router as auth_router
from app.users.router import router as users_router
from app.pets.router import router as pets_router
from app.matching.router import router as matching_router
from app.chat.router import router as chat_router
from app.moderation.router import router as moderation_router

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(pets_router)
app.include_router(matching_router)
app.include_router(chat_router)
app.include_router(moderation_router)
