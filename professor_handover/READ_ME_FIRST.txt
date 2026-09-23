DCMCS PROFESSOR HANDOVER
========================

Included files:

CURRENT ANDROID APP:
Use DCMCS-university-server.apk, rebuilt for
https://uetmardan.edu.pk/dept_comp/public/api.
Read ANDROID_INSTALL.txt. This APK does not depend on the website upload.

CURRENT WEBSITE UPDATE (same URL):
Use website-update-for-sir.zip for the existing deployment at
https://uetmardan.edu.pk/dept_comp/public/
Extract into the existing dept_comp folder and follow its READ_ME_FIRST.txt.
This adds public/site and replaces public/index.php; retain the existing .env,
database and vendor. No terminal commands or database import are needed.
The latest backend.zip also includes this website for a complete installation.
The old PENDING-DNS website ZIP and APK below still target the earlier domain;
do not use either old file for the current deployment.

1. dcmcs.sql
   MySQL database export.

2. backend.zip
   Laravel 10 server-side API source for PHP 8.1 or newer (not PHP 8.0).
   The private local .env file and generated
   dependencies are excluded. Run "composer install" and create .env from
   .env.example on the server. Read backend/DEPLOYMENT.md for full instructions.
   Use a fresh directory; do not reuse Laravel 12 vendor or cache files.
   Run composer install --no-dev --optimize-autoloader, then
   composer check-platform-reqs --no-dev. Keep the supplied composer.lock.

3. app-release-PRODUCTION-PENDING-DNS.apk
   Android client configured for
   https://dcmcs.uetmardan.edu.pk/api. It will work after university IT
   activates the domain and deploys the Laravel API.

4. web-PRODUCTION-PENDING-DNS.zip
   Compiled Flutter website configured for the proposed university API. It
   will work after DNS, HTTPS, and Laravel deployment are complete.

5. flutter-client-source.zip
   Flutter client source required to insert the final API URL and rebuild the
   APK and website.

6. API_DETAILS.txt
   API base URL, endpoints, and production build commands.

7. LOGIN_DETAILS.txt
   Demonstration web login accounts.

Required production information:

- Confirmation that the proposed public HTTPS domain has been activated
- Web hosting URL
- MySQL host, database, username, and password
- Production Laravel APP_KEY

Do not publish the system using the included demonstration passwords.

Compatibility exception:
Laravel 10 is outside security support. Its known Composer security advisories
were explicitly accepted by the project owner for this PHP 8.1 downgrade.
The Composer exception applies only to laravel/framework.
