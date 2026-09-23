"""Create the single, clearly labelled handover requested by the user."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
source = root / 'sir'
target = root / 'tommorow work.zip'
required = ['website-update-for-sir.zip', 'DCMCS-university-server.apk',
            'backend.zip', 'dcmcs.sql', 'LOGIN_DETAILS.txt',
            'flutter-client-source.zip', 'ANDROID_INSTALL.txt',
            'API_DETAILS.txt', 'READ_ME_FIRST.txt']
for name in required:
    assert (source / name).is_file(), name

instructions = '''START HERE - TOMMOROW WORK
=========================

Give sir this ONE ZIP: tommorow work.zip.
It contains the latest files together. You do not need to send earlier ZIPs.
Extract this package on a computer first; do not upload the entire package
into the website's public folder.

1. TO SHOW THE WEBSITE AT THE EXISTING LINK
   Use website-update-for-sir.zip inside this package.
   Extract it and follow its READ_ME_FIRST.txt.
   Upload the CONTENTS of its public folder to the existing dept_comp/public
   folder on the server. Back up and replace index.php and add the site folder.
   No terminal/Composer commands are needed for this website update.
   Keep the existing .env, vendor, storage and database.
   Then open https://uetmardan.edu.pk/dept_comp/public/ and press Ctrl+F5.

2. TO SHOW THE ANDROID APP
   Install DCMCS-university-server.apk on the phone.
   It uses the new university API and does not need the website upload.
   Use LOGIN_DETAILS.txt to sign in. See ANDROID_INSTALL.txt.
   Test login and complaint submission on the phone before the presentation.

3. COMPLETE PROJECT FILES FOR SIR TO KEEP
   backend.zip: latest backend, compiled website and matching vendor included.
   dcmcs.sql: original database export; do not import over the working database.
   flutter-client-source.zip: current Flutter source.
   API_DETAILS.txt and READ_ME_FIRST.txt: additional setup/reference details.

The backend is already deployed. For tomorrow's website update, use item 1;
the complete backend and database are provided as project handover files.

Website: https://uetmardan.edu.pk/dept_comp/public/
API: https://uetmardan.edu.pk/dept_comp/public/api

Builds and local checks passed. Final phone/server workflows still need testing.
'''

with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
    archive.writestr('START_HERE.txt', instructions)
    for name in required:
        archive.write(source / name, name)

with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
    assert set(archive.namelist()) == set(required + ['START_HERE.txt'])
    for name in required:
        assert archive.read(name) == (source / name).read_bytes(), name
print(f'Created and verified: {target}')
print(f'Size: {target.stat().st_size / (1024 * 1024):.1f} MB')
