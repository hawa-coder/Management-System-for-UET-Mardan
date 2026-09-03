# DCMCS architecture

DCMCS uses one Flutter client for Android and web and one Laravel API backed by
MySQL.

## Request flow

1. A user completes an action in the Flutter interface in `lib/main.dart`.
2. `lib/app_state.dart` applies client-side state and calls
   `lib/api_service.dart`.
3. The API service sends an HTTP request to a route in
   `backend/routes/api.php`.
4. A controller in `backend/app/Http/Controllers/Api` validates permissions and
   input.
5. Eloquent models in `backend/app/Models` read or update MySQL.
6. Laravel returns JSON and the Flutter store refreshes the interface.

## Authentication and roles

Laravel Sanctum issues bearer tokens after login. Protected endpoints require
that token. Controllers enforce the student, adviser, coordinator, chairman,
office, and dean workflows. Student accounts require adviser approval before
they may submit complaints.

## Deployment configuration

The Flutter API address is supplied at build time through `API_BASE_URL`.
Laravel server and database settings belong in `backend/.env`, which must never
be committed or included in a public handover.
