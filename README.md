# 🚨 NagrikAlert - Real-time Incident Reporting System

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
</p>

<p align="center">
  <b>A citizen-powered incident reporting platform for faster emergency response</b>
</p>

---

## 📖 About

**NagrikAlert** is a comprehensive incident reporting system built for the **IIT Jodhpur Development Hackathon (PROMETEO 2026)**. It enables citizens to report emergencies like fires, accidents, and medical emergencies in real-time, helping authorities respond faster.

### 🎯 Problem Statement
Traditional emergency reporting systems are slow and inefficient. NagrikAlert bridges this gap by providing:
- Real-time incident reporting with GPS
- Automatic incident verification through crowd consensus
- Admin dashboard for authorities to manage incidents

---

## ✨ Features

### 📱 Citizen App (Flutter)
- **Quick Report** - Report incidents in seconds with type, description, and severity
- **GPS Location** - Auto-capture location for accurate incident mapping
- **Real-time Updates** - See nearby incidents on an interactive map
- **Incident Tracking** - Track the status of reported incidents
- **Profile Management** - Manage your profile and view report history

### 🔐 Admin Portal
- **Dashboard Overview** - Statistics and analytics at a glance
- **Incident Management** - Verify, update, and resolve incidents
- **User Management** - Manage citizen and admin accounts
- **Audit Trail** - Complete history of all actions for accountability

### 🔧 Backend (FastAPI)
- **RESTful API** - Clean, documented API endpoints
- **Spatial Consensus** - Auto-verify incidents with 3+ device confirmations
- **GPS Deduplication** - Prevent duplicate reports within 100m radius
- **Device Fingerprinting** - Anti-spam with device tracking
- **WebSocket Feed** - Real-time updates for live dashboards

---

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│  FastAPI Server │────▶│    Supabase     │
│   (Citizens)    │     │  (HF Spaces)    │     │   (Database)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Admin Portal   │     │   WebSocket     │
│   (Flutter)     │     │   Real-time     │
└─────────────────┘     └─────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Python 3.8+
- Supabase Account

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/Shubham231005/NagrikAlert.git
cd NagrikAlert
```

### 2️⃣ Setup Flutter App
```bash
cd nagrik_alert_app
flutter pub get
flutter run
```

### 3️⃣ Setup Backend
```bash
cd NagrikAlert
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your Supabase credentials
uvicorn app.main:app --reload
```

### 4️⃣ Setup Supabase
1. Create a new Supabase project
2. Run the SQL schema from `nagrik_alert_app/supabase_schema.sql`
3. Update credentials in Flutter app and backend

---

## 📁 Project Structure

```
NagrikAlert/
├── NagrikAlert/                 # FastAPI Backend
│   ├── app/
│   │   ├── api/                # API routes
│   │   ├── models/             # Pydantic models
│   │   ├── services/           # Business logic
│   │   ├── database.py         # Database connection
│   │   └── main.py             # FastAPI app
│   ├── requirements.txt
│   └── .env.example
│
├── nagrik_alert_app/           # Flutter Mobile App
│   ├── lib/
│   │   ├── core/               # Theme, constants
│   │   ├── models/             # Data models
│   │   ├── providers/          # State management
│   │   ├── screens/            # UI screens
│   │   │   ├── auth/           # Login, Signup
│   │   │   ├── citizen/        # Citizen screens
│   │   │   └── admin/          # Admin dashboard
│   │   └── services/           # API, Auth services
│   ├── supabase_schema.sql     # Database schema
│   └── pubspec.yaml
│
└── README.md
```

---

## 🔑 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/report` | Report a new incident |
| `GET` | `/api/v1/incidents` | Get all incidents |
| `GET` | `/api/v1/incidents/{id}` | Get incident by ID |
| `PATCH` | `/api/v1/incidents/{id}/status` | Update incident status |
| `GET` | `/api/v1/stats` | Get statistics |
| `WS` | `/ws/feed` | Real-time incident feed |

📚 **Full API Documentation:** [https://shubham231005-nagrikalert.hf.space/docs](https://shubham231005-nagrikalert.hf.space/docs)

---

## 🛡️ Security Features

- **Row Level Security (RLS)** - Database-level access control
- **Device Fingerprinting** - Prevent spam and abuse
- **Rate Limiting** - Protect against DDoS attacks
- **Audit Trail** - DPDP Act compliance with immutable logs
- **Secure Authentication** - Supabase Auth with JWT

---

## 📱 Screenshots

<p align="center">
  <i>Login Screen • Home Dashboard • Report Incident • Admin Portal</i>
</p>

---

## 🌐 Live Demo

- **Backend API:** [https://shubham231005-nagrikalert.hf.space](https://shubham231005-nagrikalert.hf.space)
- **API Docs:** [https://shubham231005-nagrikalert.hf.space/docs](https://shubham231005-nagrikalert.hf.space/docs)

---

## � Demo Credentials

### 👤 Citizen Account
| Field | Value |
|-------|-------|
| **Email** | `10a.vedaantambolkaryhs@gmail.com` |
| **Password** | `123456` |

### 🛡️ Admin Account
| Field | Value |
|-------|-------|
| **Email** | `veduambolkar@gmail.com` |
| **Password** | `123456` |

> **Note:** These are demo accounts for testing purposes. Please use them responsibly.

---

## �👥 Team

| Name | Role |
|------|------|
| **Shubham** | Backend Developer |
| **Vedaant Dinesh Ambolkar** | Flutter Developer |

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Mobile App** | Flutter, Dart |
| **Backend** | FastAPI, Python |
| **Database** | PostgreSQL (Supabase) |
| **Auth** | Supabase Auth |
| **Hosting** | Hugging Face Spaces |
| **Real-time** | WebSockets |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

---

<p align="center">
  Made with ❤️ for PROMETEO 2026
</p>
