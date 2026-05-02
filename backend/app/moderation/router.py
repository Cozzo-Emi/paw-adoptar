"""
PAW — Moderation Router
Endpoints para reportes de fraude y reviews post-adopción.
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.auth.dependencies import get_current_active_moderator, get_current_user
from app.database import get_db
from app.matching.models import Match, MatchStatus
from app.moderation.models import Report, ReportStatus, Review
from app.moderation.schemas import (
    ReportCreate,
    ReportRead,
    ReportUpdate,
    ReviewCreate,
    ReviewRead,
)
from app.pets.models import Pet
from app.users.models import User

router = APIRouter(prefix="/moderation", tags=["Moderation"])


@router.post("/reports", response_model=ReportRead, status_code=status.HTTP_201_CREATED)
async def create_report(
    report_in: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Crea un reporte por comportamiento abusivo o perfil falso.
    Se puede reportar a un usuario o una mascota.
    """
    if not report_in.reported_user_id and not report_in.reported_pet_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Must report either a user or a pet.",
        )

    # Validar que no se reporte a sí mismo
    if report_in.reported_user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot report yourself.",
        )

    db_report = Report(
        reporter_id=current_user.id,
        reported_user_id=report_in.reported_user_id,
        reported_pet_id=report_in.reported_pet_id,
        reason=report_in.reason,
        description=report_in.description,
        status=ReportStatus.PENDING,
    )
    db.add(db_report)
    await db.commit()
    await db.refresh(db_report)

    return db_report


@router.post("/reviews", response_model=ReviewRead, status_code=status.HTTP_201_CREATED)
async def create_review(
    review_in: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Crea una valoración post-adopción (1-5 estrellas).
    Solo se permite si hubo un match entre los usuarios y el match está en estado COMPLETED o ACCEPTED.
    Actualiza automáticamente la reputación del usuario valorado.
    """
    if review_in.reviewed_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot review yourself.",
        )

    # Validar que el match existe y ellos son partes
    stmt = select(Match).where(Match.id == review_in.match_id)
    result = await db.execute(stmt)
    match = result.scalar_one_or_none()

    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Match not found."
        )

    if current_user.id not in [match.adopter_id, match.donor_id] or \
       review_in.reviewed_id not in [match.adopter_id, match.donor_id]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Both users must be part of the provided match.",
        )

    # Verificar si ya existe una review de este reviewer para este match
    existing_stmt = select(Review).where(
        Review.match_id == review_in.match_id,
        Review.reviewer_id == current_user.id
    )
    existing_result = await db.execute(existing_stmt)
    if existing_result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already submitted a review for this match.",
        )

    # Crear la review
    db_review = Review(
        match_id=review_in.match_id,
        reviewer_id=current_user.id,
        reviewed_id=review_in.reviewed_id,
        rating=review_in.rating,
        comment=review_in.comment,
    )
    db.add(db_review)

    # Actualizar la reputación del usuario valorado
    user_stmt = select(User).where(User.id == review_in.reviewed_id)
    user_result = await db.execute(user_stmt)
    reviewed_user = user_result.scalar_one()

    # Calcular nuevo promedio
    current_total = reviewed_user.reputation_score * reviewed_user.reputation_count
    new_count = reviewed_user.reputation_count + 1
    new_score = (current_total + review_in.rating) / new_count

    reviewed_user.reputation_score = new_score
    reviewed_user.reputation_count = new_count

    await db.commit()
    await db.refresh(db_review)

    return db_review


@router.get("/reports", response_model=list[ReportRead])
async def list_reports(
    status_filter: Optional[ReportStatus] = Query(None, alias="status"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_moderator: User = Depends(get_current_active_moderator),
    db: AsyncSession = Depends(get_db),
):
    """
    Lista reportes. Solo accesible por moderadores y admins.
    Filtra por status opcionalmente.
    """
    stmt = select(Report).options(
        selectinload(Report.reporter),
        selectinload(Report.reported_user),
    )

    if status_filter:
        stmt = stmt.where(Report.status == status_filter)

    stmt = stmt.order_by(Report.created_at.desc()).offset(offset).limit(limit)

    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/reports/{report_id}", response_model=ReportRead)
async def get_report(
    report_id,
    current_moderator: User = Depends(get_current_active_moderator),
    db: AsyncSession = Depends(get_db),
):
    """
    Obtiene detalle de un reporte específico.
    """
    from uuid import UUID

    stmt = (
        select(Report)
        .where(Report.id == UUID(report_id))
        .options(selectinload(Report.reporter), selectinload(Report.reported_user))
    )
    result = await db.execute(stmt)
    report = result.scalar_one_or_none()

    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    return report


@router.put("/reports/{report_id}", response_model=ReportRead)
async def update_report(
    report_id,
    update: ReportUpdate,
    current_moderator: User = Depends(get_current_active_moderator),
    db: AsyncSession = Depends(get_db),
):
    """
    Actualiza el estado de un reporte (resolver/descartar/revisar).
    Solo accesible por moderadores y admins.
    """
    from uuid import UUID
    from datetime import datetime, timezone

    stmt = select(Report).where(Report.id == UUID(report_id))
    result = await db.execute(stmt)
    report = result.scalar_one_or_none()

    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    report.status = update.status
    report.moderator_id = current_moderator.id

    if update.resolution_notes:
        report.resolution_notes = update.resolution_notes

    if update.status in (ReportStatus.RESOLVED, ReportStatus.DISMISSED):
        report.resolved_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(report)

    return report
