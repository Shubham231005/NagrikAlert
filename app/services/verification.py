import hashlib
from geopy.distance import geodesic
from sqlalchemy.orm import Session
from app.models.incident import DBIncident, DBAuditLog, DBDeviceRegistry

def get_device_hash(raw_id: str):
    return hashlib.sha256(raw_id.encode()).hexdigest()

def verify_incident_logic(db: Session, incident: DBIncident, raw_device_id: str):
    """
    1. Checks if Device is Banned.
    2. Performs GPS Fencing (100m Consensus).
    3. Logs to Audit Trail.
    """
    d_hash = get_device_hash(raw_device_id)

    # 1. Device Check
    device = db.query(DBDeviceRegistry).filter_by(device_hash=d_hash).first()
    if not device:
        # Register new device
        new_device = DBDeviceRegistry(device_hash=d_hash)
        db.add(new_device)
    elif device.is_banned:
        return "REJECTED_BANNED_DEVICE"

    # 2. Spatial Consensus (100m Radius Rule)
    # Find active incidents of same type within 100m
    all_incidents = db.query(DBIncident).filter(
        DBIncident.type == incident.type,
        DBIncident.status != "Resolved"
    ).all()

    nearby_count = 0
    unique_reporters = set()

    for inc in all_incidents:
        if inc.id == incident.id: continue # Skip self

        dist = geodesic((incident.latitude, incident.longitude),
                        (inc.latitude, inc.longitude)).meters
        if dist <= 100: # 100 Meters Radius
            nearby_count += 1
            unique_reporters.add(inc.device_hash)

    # If 3+ unique devices report nearby, Auto-Verify
    # (Current report + 2 others = 3)
    if len(unique_reporters) >= 2:
        incident.status = "Verified"
        # 3. Create Audit Log
        log = DBAuditLog(
            incident_id=incident.id,
            action="AUTO_VERIFIED",
            performed_by="SYSTEM",
            details=f"Consensus matched with {len(unique_reporters)+1} devices"
        )
        db.add(log)
        return "Verified"

    return "Unverified"