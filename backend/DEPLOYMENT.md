# Laravel 10 server setup

The current university website URL is
`https://uetmardan.edu.pk/dept_comp/public/`, with the API under `/api`.
The bundled `public/site` website is built for that path. The homepage route
serves its index file. To update the existing deployed backend, use
`website-update-for-sir.zip` and its README; retain its database and APP_KEY.

This backend targets PHP 8.1 or newer using Laravel 10 and Sanctum 3.
PHP 8.0 and PHP 7.x are not compatible. Both the website PHP handler and CLI
must meet the requirements. Composer resolves dependencies against PHP 8.1.0
through `config.platform`; the server must still pass the real platform check.

Laravel 10 is end of security support. The project owner explicitly accepted
the Composer advisory exception for `laravel/framework` for this downgrade.
Other packages retain Composer's default advisory blocking. This is a legacy
compatibility deployment, not a currently supported Laravel release.

1. Extract the backend archive into a new application directory. Do not reuse
   the old Laravel 12 vendor folder or cached PHP files.
2. Create a MySQL database and import `dcmcs.sql`. For an existing deployment,
   back up its database and use its current data instead of importing demo data.
3. Copy `.env.example` to `.env`. Set the database host, name, username and
   password, `APP_ENV=production`, `APP_DEBUG=false`, and the public `APP_URL`.
   Preserve the existing APP_KEY when updating an existing deployment.
4. In the directory containing `artisan` and `composer.json`, run:

   ```sh
   composer install --no-dev --optimize-autoloader
   composer check-platform-reqs --no-dev
   ```

   Keep `composer.lock`; do not run `composer update` on the server.

5. On a first installation only, run `php artisan key:generate`. Then run:

   ```sh
   php artisan config:clear
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

6. Set the web server document root to `backend/public` (or `public` inside
   your extracted application directory). Allow its PHP process to write to
   `storage` and `bootstrap/cache`. Configure DNS and HTTPS.
7. Test `/up`, `/api/advisers`, app login, and an attachment upload/download.
   The bundled website targets `https://uetmardan.edu.pk/dept_comp/public/api`.
   Use DCMCS-university-server.apk for this API; the earlier PENDING-DNS APK
   still targets the old domain.

The default mailer logs mail. Set a working SMTP mailer for password reset
delivery, including MAIL_HOST, MAIL_PORT, MAIL_USERNAME, MAIL_PASSWORD and
MAIL_ENCRYPTION (usually tls). Replace demonstration account passwords before
making the application public.

On this Windows development computer PHP can be invoked with
`C:\xampp\php\php.exe`, and Composer with
`C:\xampp\php\php.exe ..\composer.phar` from the backend directory.

Verification: Laravel 10.50.3; 21 tests and 63 assertions passed on PHP 8.2.12
using an isolated SQLite test database. A fresh installation from backend.zip
passed Composer installation without development dependencies, platform checks,
key generation, and configuration/route/view caching. Dependencies were resolved
for PHP 8.1.0; an actual PHP 8.1 runtime and the university server were not available
for testing. The existing MySQL export was not modified.
