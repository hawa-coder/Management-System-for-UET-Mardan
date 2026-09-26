# DCMCS — Department Complaint Management and Communication System

Department Complaint Management & Communication System for UET Mardan.

DCMCS is a Department Complaint Management and Communication System for UET Mardan. It provides responsive onboarding and authentication screens, university-email validation, seven institutional roles, complaint creation and filtering, complaint timelines, role-based workflows, dashboard analytics, notices, and user profiles.

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

## Complaint routing

Complaint cards and details show the student's registration number, named sender
and recipient, original forwarding Batch Adviser, current holder, and timestamp.
The **Routing History** retains every submission, forwarding, return, and status
change, including comments and the names and roles saved at the time of the action.
Previous participants retain access to the history. Only the current holder can
change a complaint or forward it. Chairmen and Department Staff retain department
oversight; deans retain university oversight.

Use **Forward Complaint** or **Return Complaint** to select an active, approved
staff member in the student's department, the assigned adviser, or a dean. The
selected person's role appears automatically. Returns have the **Returned** status.
Faculty members can forward only when an administrator grants this permission:

```powershell
C:\xampp\php\php.exe backend\artisan complaints:forward-permission faculty@uetmardan.edu.pk
```

Add `--revoke` to remove the permission. The permission cannot be granted through
public registration. Apply the routing schema before starting the updated app:

```powershell
C:\xampp\php\php.exe backend\artisan migrate
```

Existing history is retained. Known historical actors are recovered from saved
user IDs; recipients whose identities were never stored display **Name not
recorded**. New routing events always save a named recipient. A legacy role queue
is claimed by its first authorized handler under a database lock.

## Targeted notices

Approved chairmen, batch advisers, faculty members, coordinators, and deans can
select **Create Notice** on the dashboard or notice board. The form supports a
title, message, category, Normal/Important/Urgent priority, publication date and
time, optional expiry, and an optional PDF, image, Word, text, or OpenDocument
attachment (up to 10 MB).

Select multiple departments/fields, batches, semesters, sections, courses, or
individual students. Values within one group are alternatives; every selected
group must match. An empty group leaves that filter unrestricted within the
author's permissions. Choices use current student profile values (for example,
`FA23` and `23` remain distinct stored batches).

Chairmen and coordinators are limited to their own department; advisers to
their assigned students; faculty to students enrolled in their teaching
assignments within their department. Faculty need the administrator-controlled
`users.can_publish_department_notices` permission for department-wide notices.
Deans can target university-wide audiences. Public registration cannot grant
faculty roles or department-wide permissions.

The student board shows only active notices matching the current profile and
course enrollments. Urgent notices appear first. Search, category/priority,
date-range, and read/unread filters are available. The dashboard shows three
notices and **View All Notices**. Opening a notice marks it and its linked bell
notification as read. The app refreshes announcements every 30 seconds while
signed in, with manual refresh also available.

**My Notices** lets authors view, edit, delete, and re-publish their own active,
scheduled, or expired notices. Editing updates the audience, resets read state,
and sends the revised notice when due. Re-publishing publishes immediately,
clears the previous expiry, and resets read state; use Edit to set a new expiry.
Attachments are stored privately and served through short-lived signed links
that recheck recipient access. Existing Department Staff resolution notices
continue to work.

Apply the schema update to an existing installation:

```powershell
C:\xampp\php\php.exe backend\artisan migrate
```

Faculty accounts use the server-assigned `faculty` role and the **Faculty Member**
sign-in option. Faculty accounts must be provisioned by the system administrator;
public registration continues to create student accounts only.

An administrator with server access can grant department-wide publishing with
`php artisan notices:faculty-permission faculty@uetmardan.edu.pk`; add `--revoke`
to restrict future notices to teaching assignments again.

This project did not previously have course enrollment data. Administrators can
add a teaching assignment and enroll existing students using unique class/course
codes (use a distinct code per class offering):

```powershell
cd backend
C:\xampp\php\php.exe artisan notices:assign-course CS301-FA23-A "Algorithms, FA23 Section A" faculty@uetmardan.edu.pk --student=2023cs001@uetmardan.edu.pk
```

Repeat `--student=email` for multiple students. The command adds enrollments
without removing existing students. Course ownership and enrollment data live
in `courses` and `course_student`; keep them synchronized with university class
assignments. A faculty account without teaching assignments and without the
department-wide permission cannot reach any students.

For scheduled delivery, run Laravel's scheduler every minute on the server
(`php artisan schedule:run` via cron or Windows Task Scheduler). During local
development, run `C:\xampp\php\php.exe artisan schedule:work`. Due notices are
also dispatched when notices or notifications are fetched, so schedules remain
usable during local testing without a scheduler process. Delivery is idempotent;
expired and scheduled notices are excluded from student boards and bells.

Verification:

```powershell
C:\xampp\php\php.exe backend\artisan test
flutter analyze --no-pub
flutter test --no-pub
```
