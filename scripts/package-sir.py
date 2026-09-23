"""Prepare the current upload-only handover, preserving a backup first."""
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
dest = root / 'sir'
source = root / 'professor_handover'
production = root / 'backups/laravel10-package-check/backend'
assert (production / 'composer.lock').read_bytes() == (root / 'backend/composer.lock').read_bytes()
assert (production / 'vendor/autoload.php').is_file()
backup = root / 'backups' / ('sir-before-update-' + datetime.now().strftime('%Y%m%d-%H%M%S') + '.zip')
with zipfile.ZipFile(backup, 'w', zipfile.ZIP_DEFLATED) as out:
    for path in sorted(dest.rglob('*')):
        if path.is_file():
            out.write(path, path.relative_to(root).as_posix())

with zipfile.ZipFile(source / 'backend.zip') as original, zipfile.ZipFile(dest / 'backend.zip', 'w', zipfile.ZIP_DEFLATED) as out:
    for name in original.namelist():
        out.writestr(name, original.read(name))
    for path in sorted((production / 'vendor').rglob('*')):
        if path.is_file() and not path.name.startswith('tmp-'):
            out.write(path, 'backend/' + path.relative_to(production).as_posix())

for name in ['DCMCS-university-server.apk', 'website-update-for-sir.zip', 'dcmcs.sql',
             'LOGIN_DETAILS.txt', 'API_DETAILS.txt', 'ANDROID_INSTALL.txt']:
    shutil.copy2(source / name, dest / name)

# Refresh the Flutter source archive from current project files.
paths = ['lib', 'assets', 'android', 'ios', 'linux', 'macos', 'windows', 'web', 'test',
         'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'README.md',
         'scripts/build-production.ps1']
names = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', *paths], cwd=root, text=True).splitlines()
with zipfile.ZipFile(dest / 'flutter-client-source.zip', 'w', zipfile.ZIP_DEFLATED) as out:
    for name in sorted(set(names)):
        path = root / name
        if path.is_file() and path.name not in ['local.properties', 'key.properties'] and path.suffix not in ['.jks', '.keystore']:
            out.write(path, name)

(dest / 'READ_ME_FIRST.txt').write_text('''CURRENT HANDOVER FOR SIR
========================

Website: https://uetmardan.edu.pk/dept_comp/public/
API: https://uetmardan.edu.pk/dept_comp/public/api

THE BACKEND IS ALREADY DEPLOYED:
Use website-update-for-sir.zip to add the website without terminal commands.
Extract it, then upload the CONTENTS of its public folder into the existing
dept_comp/public folder. Back up and replace public/index.php and upload the
new site folder. Keep the existing .env, vendor, storage and database.
Read the detailed instructions inside that ZIP. Then open the website and
press Ctrl+F5. If server PHP caching retains old code, ask IT to reload PHP.

ANDROID APP:
Install DCMCS-university-server.apk on the phone. It connects to the current
API and does not need the website upload. See ANDROID_INSTALL.txt and
LOGIN_DETAILS.txt. Test login and complaint submission before the demo.

COMPLETE BACKEND:
backend.zip includes the latest Laravel 10 code, compiled website AND the
matching production vendor folder (including vendor/autoload.php). There is
no need to run Composer just to obtain these dependencies. PHP 8.1+ and the
required PHP extensions are still necessary. The archive contains a backend
folder: its contents correspond to the server's existing dept_comp folder.
Preserve the server's .env/APP_KEY, storage and database when updating.
This is NOT a reason to replace the working deployment before the demo.
For a fresh installation, IT must configure .env, an APP_KEY, MySQL and hosting;
see backend/DEPLOYMENT.md. The website update ZIP is the simplest option now.

DATABASE:
dcmcs.sql is the original database export for a fresh installation/backup.
Do not import it over the existing working database.

SOURCE:
flutter-client-source.zip contains the current Flutter source and build script.
API_DETAILS.txt records the current API URL and build commands.

CHECKS AND LIMITS:
Backend: 21 tests, 66 assertions passed locally. Website release build passed.
APK build, signature and embedded API address checks passed. Phone login and
full university-server workflows still need testing. The APK is a demo build
using the existing development signing key, not a Play Store release.
Laravel 10's previously accepted security-advisory exception remains in place.
Replace demo passwords before public use; configure SMTP for email delivery.

Use this sir folder/ZIP instead of earlier PENDING-DNS packages.
''', encoding='utf-8')

with zipfile.ZipFile(dest / 'backend.zip') as archive:
    assert archive.testzip() is None
    for name in ['backend/vendor/autoload.php', 'backend/public/site/index.html',
                 'backend/public/index.php', 'backend/composer.lock']:
        assert name in archive.namelist(), name
    assert 'backend/.env' not in archive.namelist()
    assert '80100' in archive.read('backend/vendor/composer/platform_check.php').decode()
for path in dest.glob('*.zip'):
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None, path

with zipfile.ZipFile(root / 'sir.zip', 'w', zipfile.ZIP_DEFLATED) as out:
    for path in sorted(dest.rglob('*')):
        if path.is_file():
            out.write(path, path.relative_to(root).as_posix())
with zipfile.ZipFile(root / 'sir.zip') as archive:
    assert archive.testzip() is None
print('Updated sir folder and sir.zip. Backend includes production vendor.')
print('Previous sir files backed up to ' + str(backup))
