from fastapi import APIRouter, HTTPException
from sqlalchemy import text

from pluris_server.dependencies import Db

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/ready")
async def ready(db: Db) -> dict[str, str]:
    try:
        await db.execute(text("SELECT 1"))
    except Exception as error:
        raise HTTPException(status_code=503, detail="Database is unavailable") from error
    return {"status": "ready"}
