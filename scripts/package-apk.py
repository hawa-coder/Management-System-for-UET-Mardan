"""Validate and copy the Android build configured for the university server."""
from pathlib import Path
import hashlib
import shutil
import zipfile

root = Path(__file__).resolve().parents[1]
apk = root / 'build/app/outputs/flutter-apk/app-release.apk'
api = b'https://uetmardan.edu.pk/dept_comp/public/api'
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None, 'APK integrity check failed'
    libraries = [n for n in archive.namelist() if n.endswith('/libapp.so')]
    assert libraries, 'Compiled Flutter libraries missing'
    for name in libraries:
        assert api in archive.read(name), f'Expected API address missing from {name}'
    print(f'API address verified in {len(libraries)} architecture libraries.')
for folder in [root, root / 'professor_handover']:
    target = folder / 'DCMCS-university-server.apk'
    shutil.copy2(apk, target)
    print(f'Created {target}')
print('SHA256: ' + hashlib.sha256(apk.read_bytes()).hexdigest())
