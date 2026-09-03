DCMCS PROFESSOR HANDOVER
========================

Included files:

1. dcmcs.sql
   MySQL database export.

2. backend.zip
   Laravel server-side API source. The private local .env file and generated
   dependencies are excluded. Run "composer install" and create .env from
   .env.example on the server.

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
