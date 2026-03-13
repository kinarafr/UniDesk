<p align="left">
  <img src="Images/App/UniDesk White.png" width="150" alt="UniDesk Logo">
</p>

# UniDesk

UniDesk is a comprehensive university management and administrative ticketing system built with **Flutter** and **Firebase**. It provides a unified platform for students, teachers, and administrators to streamline university services and ticket resolution.

---

## 🚀 Features

### 📱 Client App (Students & Teachers)
- 🔐 **Authentication**: Secure login via Firebase Auth.
- 🏠 **Home Dashboard**: Quick overview of activity, actions, and upcoming schedules.
- 🛠 **Ticketing System (Services)**:
  - 💻 **Laptop Requests**: Request university hardware.
  - 🔧 **Maintenance**: Report computer or facility issues.
  - 🎒 **Lost & Found**: Report missing items.
  - 📅 **Appointments**: Book time with lecturers.
  - 💳 **Payments**: Check pending university dues.
  - 📞 **Contact**: Direct communication with staff.
- 📅 **Timetable**: View and manage class schedules and events.
- 👤 **Profile**: Manage settings and track ticket history.
- 🎨 **Theming**: Premium dark and light mode support with NIBM branding.

### 💻 Admin Dashboard
- 🎫 **Ticket Management**: Centralized view to track and resolve user tickets.
- 👥 **User Management**: Oversee and manage student/teacher accounts.
- 🌐 **Web Interface**: Optimized for browsers to ensure efficient administration.

---

## 📁 Project Structure

This repository contains two main applications:

- `unidesk_client/`: Cross-platform mobile/web application for students and teachers.
- `unidesk_admin/`: Flutter-based web dashboard for administrators.
- `Images/`, `NIBM logos/`, `SVG/`: Shared branding and assets.

---

## ⚙️ Technical Stack

| Component | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) (Dart) |
| **Backend** | Firebase (Auth, Cloud Firestore) |
| **Scheduling** | `table_calendar`, `intl` |
| **UI/UX** | `google_fonts`, `flutter_svg`, `cupertino_icons` |

---

## 🛠 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11.0 or higher)
- Firebase project with Firestore and Auth enabled.

### 1. Environment Setup
Configure environment variables for both apps:
1. Copy `unidesk_admin/.env.example` to `.env` in both `unidesk_admin/` and `unidesk_client/`.
2. Populate the `.env` files with your Firebase configuration.

### 2. Run Applications

**Client App:**
```bash
cd unidesk_client
flutter pub get
npm start
```

**Admin Dashboard:**
```bash
cd unidesk_admin
flutter pub get
npm start
```

---

## 📄 License
This project is private and not intended for public distribution.
