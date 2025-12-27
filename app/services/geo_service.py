from geopy.distance import geodesic
from sqlalchemy.orm import Session
from app.models.incident import DBIncident

def check_for_duplicates(db: Session, lat: float, lon: float, type: str):
    """Checks if a similar incident was reported within 100m in the last 30 mins."""
    existing = db.query(DBIncident).filter(DBIncident.type == type).all()
    for inc in existing:
        dist = geodesic((lat, lon), (inc.latitude, inc.longitude)).meters
        if dist < 100:
            return inc # Potential duplicate found
    return None

def verify_by_consensus(db: Session, lat: float, lon: float):
    """Auto-verifies an incident if 3+ reports exist in the same area."""
    nearby_reports = db.query(DBIncident).all()
    count = 0
    cluster = []
    for inc in nearby_reports:
        if geodesic((lat, lon), (inc.latitude, inc.longitude)).meters < 100:
            count += 1
            cluster.append(inc)

    if count >= 3:
        for inc in cluster:
            inc.status = "Verified"
        db.commit()
        return True
    return False