# DCMCS — Department Complaint Management and Communication System

Department Complaint Management & Communication System for UET Mardan.

DCMCS is a Department Complaint Management and Communication System for UET Mardan. It provides responsive onboarding and authentication screens, university-email validation, six institutional roles, complaint creation and filtering, complaint timelines, role-based workflows, dashboard analytics, notices, and user profiles.

## Run

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

For the Android emulator, the application automatically uses `http://10.0.2.2:8000/api`. For a physical phone, replace `127.0.0.1` with the development computer's LAN IP address.

## Run as a website

The same Flutter project includes a responsive laptop/desktop layout. Start the
Laravel API first, then launch the web app with the API address that users'
browsers can reach:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Replace `192.168.1.10` with the LAN IP address of the computer running Laravel.
Using `127.0.0.1` only works when the browser and Laravel are on the same
computer.

To create deployable website files:

```sh
flutter build web --release --dart-define=API_BASE_URL=https://your-domain.example/api
```

Upload the contents of `build/web/` to the web server. In production, host the
Flutter website and Laravel API over HTTPS. The website and mobile application
use the same accounts, roles, complaints, notices, and MySQL database.

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

## Proposed university deployment

The production configuration is prepared for:

```text
Website: https://dcmcs.uetmardan.edu.pk
API:     https://dcmcs.uetmardan.edu.pk/api
```

University IT must create the DNS record and HTTPS certificate before these
addresses can work. Copy `backend/.env.production.example` to `backend/.env` on
the server, insert the real database and mail credentials, and generate the
Laravel application key. Build both clients by running:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build-production.ps1
```

## Initial accounts

| Role | Email | Initial password |
| --- | --- | --- |
| Student | `2023cs001@uetmardan.edu.pk` | `Student@123` |
| Batch Adviser | `adviser@uetmardan.edu.pk` | `Adviser@123` |
| Coordinator | `coordinator@uetmardan.edu.pk` | `Coordinator@123` |
| Chairman | `chairman@uetmardan.edu.pk` | `Chairman@123` |
| Department Staff | `office@uetmardan.edu.pk` | `Office@123` |
| Dean | `dean@uetmardan.edu.pk` | `Dean@123` |

These initial passwords must be changed before production deployment. Production must also use HTTPS and a password-protected MySQL account rather than the local XAMPP root account.

## Core modules

- Secure university account access
- Student complaint submission and tracking
- Role-based administrative routing
- Complaint status history and resolution actions
- Department notices and announcements
- Responsive dashboards and user profiles
