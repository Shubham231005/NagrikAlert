Markdown

# 🚨 NagrikAlert - Backend API Documentation
**IIT Jodhpur Development Hackathon (PROMETEO 2026)**

This backend handles **Real-time Incident Reporting**, **Spatial De-duplication**, and **Device Fingerprinting** using FastAPI and Supabase.

---

## 🔗 Base Configuration

| Service | Details |
| :--- | :--- |
| **Base URL** | `https://shubham231005-nagrikalert.hf.space` |
| **WebSocket URL** | `wss://nagrikalert.hf.space/ws/feed` |
| **Docs (Swagger)** | `https://shubham231005-nagrikalert.hf.space/docs` |
| **Deployment** | Hugging Face Spaces (Dockerized) |

---

## 📱 Flutter Integration Guide

### 1. Mandatory Headers (Critical)
Every request to the reporting API **MUST** include the Device ID. This is used for the **Anti-Spam & Fingerprinting** logic.

```dart
Map<String, String> headers = {
  "Content-Type": "application/json",
  "x-device-id": "UNIQUE_HARDWARE_ID" // Use 'device_info_plus' package to get this
};
2. Report an Incident (POST)
Endpoint: /api/v1/report

Request Body (JSON):

JSON

{
  "type": "Fire",               // String: Fire, Accident, Medical, Infrastructure
  "description": "Huge fire near the petrol pump",
  "latitude": 28.7041,          // Double
  "longitude": 77.1025,         // Double
  "severity": 5,                // Integer: 1 (Low) to 5 (Critical)
  "reporter_id": "user_123"     // String: User's auth ID (if logged in) or "anon"
}
Success Response (200 OK):

JSON

{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "Verified",         // Could be "Unverified" or "Verified" (Auto-consensus)
  "timestamp": "2025-12-27T10:00:00"
}
Error Responses:

403 Forbidden: "Device Banned" (If x-device-id is flagged in Supabase).

409 Conflict: "Duplicate Report" (If reported too recently from same location).

3. Live Responder Feed (WebSocket)
Endpoint: /ws/feed Logic: Connect to this stream on the Admin/Responder Dashboard screen.

Stream Data Format: You will receive a JSON string whenever a NEW report comes in.

JSON

{
  "type": "NEW_INCIDENT",
  "id": "550e8400...",
  "lat": 28.7041,
  "lng": 77.1025,
  "status": "Unverified",
  "severity": 5
}
Tip: Use the web_socket_channel package in Flutter to listen to this stream and update the Map markers in real-time.

🧠 Backend Logic (For Presentation)
The Flutter app is powered by a "Smart Backend" that handles the PDF constraints:

Spatial Consensus Engine:

The backend checks if 3 different devices have reported the same incident type within a 100m radius.

If yes, the status automatically flips from Unverified -> Verified.

Flutter Action: Show "Verified" reports with a Green Marker and others with a Yellow Marker.

Audit Trail:

Every status change is logged immutably in the SQL database for legal accountability (DPDP Act compliance).

Device Fingerprinting:

We hash the x-device-id header. If a user tries to spam fake reports, their specific device is banned backend-side.

🛠 Project Structure (Backend)
Plaintext

NagrikAlert/
├── app/
│   ├── api/            # API Routes (citizen_api.py)
│   ├── core/           # Config (Supabase URL)
│   ├── models/         # Database Tables (Incidents, Audit Logs)
│   ├── services/       # The "Brains" (verification.py, ws_manager.py)
│   └── main.py         # Entry Point
├── Dockerfile          # Deployment Config
└── requirements.txt    # Dependencies
🚀 How to Run Locally (Optional)
If you want to test without Hugging Face:

pip install -r requirements.txt

uvicorn app.main:app --reload

Base URL becomes