# Monitoring System — Flutter Client App

A modern, responsive cross-platform Flutter application for user case submission, tracking, and response notifications.

## Features

- 🔐 **Authentication**: User registration and JWT-based authentication with automatic session persistence.
- 📝 **Case Submission**: Interactive multi-step form with category & priority selectors, validation, and instantaneous server synchronization.
- 📊 **Status Tracker**: Visual real-time 5-stage progress indicator (`Pending` → `Under Review` → `Assigned` → `Resolved` → `Closed`).
- 💬 **Direct Response Feed**: Threaded replies from Administrators and Assigned Secretaries.
- 🔔 **Notifications**: In-app unread notification indicators on case updates and responses.

## Folder Structure

```
client/
├── lib/
│   ├── main.dart                      # App entry point & theme configuration
│   ├── models/                        # Typed data transfer models
│   │   ├── submission.dart
│   │   ├── user.dart
│   │   └── response.dart
│   ├── services/                      # Network & local state services
│   │   ├── api_service.dart           # Base HTTP client with JWT interceptor
│   │   ├── auth_service.dart          # Auth & token management
│   │   └── submission_service.dart    # Submission & notification endpoints
│   ├── screens/                       # User interfaces
│   │   ├── login_screen.dart          # Sign in / Sign up screen
│   │   ├── home_screen.dart           # Submissions dashboard & filter chips
│   │   ├── submission_screen.dart     # New case creation form
│   │   └── submission_status_screen.dart # Progress tracker & chat responses
│   ├── widgets/                       # Reusable UI components
│   │   ├── form_field.dart
│   │   ├── submit_button.dart
│   │   └── status_card.dart
│   └── utils/                         # Global constants & validators
│       ├── constants.dart
│       └── validators.dart
├── pubspec.yaml
└── README.md
```

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version `>=3.0.0`)
- Android Studio / Xcode / VS Code with Flutter Extension

### Setup & Run

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure API URL**:
   Open [`lib/utils/constants.dart`](file:///c:/Users/HP/Desktop/serverClientSystem/monitoring-system/client/lib/utils/constants.dart) and configure `baseUrl`:
   - Android Emulator: `http://10.0.2.2:5000/api`
   - iOS Simulator / Web / Desktop: `http://localhost:5000/api`
   - Physical Device: `http://<YOUR_LOCAL_IP>:5000/api`

3. **Run Application**:
   ```bash
   flutter run
   ```
