# UniDesk

UniDesk is a comprehensive university management and administrative ticketing system built with Flutter and Firebase. It caters to both students and teachers by providing a unified platform for various university services, alongside a dedicated dashboard for administrators to manage and resolve tickets efficiently.

## 🚀 Features

### Client App (Students & Teachers)
- **Authentication**: Secure login for both students and teachers using Firebase Auth.
- **Home Dashboard**: Quick overview of recent activity, quick actions, and upcoming events/classes.
- **Ticketing System (Services)**:
  - Request laptops.
  - Report computer issues or maintenance requirements.
  - Report missing items.
  - Book appointments with lecturers.
  - Check pending payments.
  - Contact university staff directly.
- **Timetable**: View and manage class schedules and upcoming events.
- **Profile Management**: Manage personal information, settings, and view ticketing history.
- **Theming**: Light and dark mode support with institution-specific (NIBM) branding and logos.

### Admin Dashboard
- **Ticket Management**: View, track, and resolve tickets submitted by students and teachers.
- **User Management**: Oversee student and teacher accounts.
- **Web Interface**: Optimized for web operation to ensure administrators can work efficiently.

## 📁 Project Structure

This repository is structured into two main applications:

- `unidesk_client/`: The primary cross-platform (iOS, Android) Flutter application used by students and teachers.
- `unidesk_admin/`: A Flutter-based admin dashboard (typically run as a web app) for administrators to manage the platform.
- `Images/` & `NIBM logos/` & `SVG/`: Shared resources and branding assets used across the platform.

## 💻 Technical Info 

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend/Database**: Firebase (Authentication, Cloud Firestore)
- **Key Packages**:
  - `firebase_core`, `firebase_auth`, `cloud_firestore` for backend integration.
  - `table_calendar`, `intl` for scheduling and timetable features.
  - `google_fonts`, `flutter_svg`, `cupertino_icons` for styling and iconography.

## 🛠 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.11.0 or higher recommended)
- Firebase project setup with Firestore and Authentication enabled.

### 1. Environment Setup

Both applications require Firebase configuration. You must create a `.env` file in the root of the respective application directories (`unidesk_admin/` and `unidesk_client/`).

**To set up your environment:**
1. Copy the contents of `.env.example` (found in `unidesk_admin/`) into a new file named `.env` in both the `unidesk_admin/` and `unidesk_client/` directories.
2. Fill in the required Firebase secrets (API keys, project IDs, etc.) in each `.env` file.

*(Make sure `.env` is added to your `.gitignore` to prevent secret leaks).*

### 2. Running the Client App

Navigate to the client directory, get dependencies, and run:

```bash
cd unidesk_client
flutter pub get

# To run using npm scripts (Web/Edge):
npm start

# Or using flutter directly:
flutter run
```

To build for web:
```bash
npm run build:web
```

### 3. Running the Admin Dashboard

Navigate to the admin directory, get dependencies, and run. Note that the admin dashboard relies on the `.env` file:

```bash
cd unidesk_admin
flutter pub get

# To run using npm scripts:
npm start

# Or using flutter directly:
flutter run --dart-define-from-file=.env
```

To build for web:
```bash
npm run build:web
```

## 📄 License & Publishing

These packages are marked as private and are not intended for publishing.
