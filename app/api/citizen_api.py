from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.incident import DBIncident, IncidentCreate, IncidentResponse
from app.services.verification import verify_incident_logic
from app.services.ws_manager import manager
import uuid
import hashlib

router = APIRouter()

@router.post("/report", response_model=IncidentResponse)
async def create_report(
    data: IncidentCreate,
    db: Session = Depends(get_db),
    x_device_id: str = Header(...) # Mandatory Header from Flutter
):
    # 1. Create Incident Object
    new_inc = DBIncident(
        **data.dict(),
        id=str(uuid.uuid4()),
        device_hash=hashlib.sha256(x_device_id.encode()).hexdigest()
    )
    db.add(new_inc)
    db.flush() # Get ID before commit

    # 2. Run Advanced Verification
    import hashlib # re-import for safety if needed scope-wise
    status = verify_incident_logic(db, new_inc, x_device_id)

    if status == "REJECTED_BANNED_DEVICE":
        db.rollback()
        raise HTTPException(status_code=403, detail="Device Banned")

    db.commit()
    db.refresh(new_inc)

    # 3. Broadcast to Live Dashboard
    await manager.broadcast({
        "type": "NEW_INCIDENT",
        "id": new_inc.id,
        "lat": new_inc.latitude,
        "lng": new_inc.longitude,
        "status": new_inc.status,
        "severity": new_inc.severity
    })

    return new_inc