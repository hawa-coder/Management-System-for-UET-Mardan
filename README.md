# DCMCS

Department Complaint Management & Communication System for UET Mardan.

DCMCS is a Department Complaint Management and Communication System for UET Mardan. It provides responsive onboarding and authentication screens, university-email validation, six institutional roles, complaint creation and filtering, complaint timelines, role-based workflows, dashboard analytics, notices, and user profiles.

## Run

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

For the Android emulator, the application automatically uses `http://10.0.2.2:8000/api`. For a physical phone, replace `127.0.0.1` with the development computer's LAN IP address.

## Backend

The Laravel API is in `backend/` and uses the XAMPP MySQL service.

1. Start MySQL in XAMPP.
2. Create and seed the schema:

```sh
C:\xampp\php\php.exe backend\artisan migrate --seed
```

3. Start the API:

```sh
cd backend
C:\xampp\php\php.exe artisan serve --host=0.0.0.0 --port=8000
```

The API implements Sanctum token authentication, server-controlled roles, complaints, workflow transitions, notices, notifications and complaint audit history.

## Initial accounts

| Role | Email | Initial password |
| --- | --- | --- |
| Student | `2023cs001@uetmardan.edu.pk` | `Student@123` |
| Batch Adviser | `adviser@uetmardan.edu.pk` | `Adviser@123` |
| Coordinator | `coordinator@uetmardan.edu.pk` | `Coordinator@123` |
| Chairman | `chairman@uetmardan.edu.pk` | `Chairman@123` |
| Office Staff | `office@uetmardan.edu.pk` | `Office@123` |
| Dean | `dean@uetmardan.edu.pk` | `Dean@123` |

These initial passwords must be changed before production deployment. Production must also use HTTPS and a password-protected MySQL account rather than the local XAMPP root account.

## Core modules

- Secure university account access
- Student complaint submission and tracking
- Role-based administrative routing
- Complaint status history and resolution actions
- Department notices and announcements
- Responsive dashboards and user profiles
