# Local verification — 2026-09-15

## Passed

- Laravel 10.50.3: 21 automated tests, 63 assertions, on PHP 8.2.12.
- Tests cover registration/login, approval ownership, adviser approval listing,
  password reset expiration/token revocation, notice publishing permissions,
  complaint workflows, signed attachment downloads, CORS, and blocked accounts.
- Flutter analysis: no issues. Flutter onboarding/login widget test passed.
- Flutter release web build with the university API URL succeeded.
- Existing local database: every migration is applied.
- All six credentials in professor_handover/LOGIN_DETAILS.txt match active,
  approved local accounts. Checks did not change passwords or create sessions.
- /up and /api/advisers return HTTP 200 through the local application kernel.
- Composer's generated PHP check now requires PHP >= 8.1.0.

## Fixed during this check

- Replaced MySQL-only FIELD ordering in adviser approvals with portable CASE
  ordering, preserving pending/approved/rejected order.
- Blocked existing API tokens when their account is disabled/rejected, or when
  a non-student account awaits approval. Pending students can still view status.
- Corrected the handover adviser email: the old generic account was disabled;
  shams.ur.rahman@uetmardan.edu.pk is an active demo account.
- Expanded regression tests and provided scripts/check-demo-logins.php for
  repeatable, read-only local credential and endpoint checks.

## Limits

This is not a claim that every screen and device was manually verified. The
in-app browser was unavailable. Android/iOS device testing, actual PHP 8.1
execution, university hosting/DNS/HTTPS, and SMTP delivery were not verified.
The supplied clients target https://dcmcs.uetmardan.edu.pk/api; local backend
success does not establish that the public deployment is working.

Laravel 10 retains the previously accepted Composer security advisory exception.
The default mail configuration logs messages; real email needs SMTP setup.
The MySQL export was not replaced with local data during these checks.
