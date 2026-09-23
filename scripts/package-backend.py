"""Build a source-only professor handover archive without local credentials/data."""
from pathlib import Path
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
names = subprocess.check_output(
    ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', 'backend'],
    cwd=root, text=True,
).splitlines()
# Generated Flutter assets are ignored by Git but required by the combined deployment.
names += [p.relative_to(root).as_posix() for p in (root / 'backend/public/site').rglob('*') if p.is_file()]
archive = root / 'professor_handover' / 'backend.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as out:
    for name in sorted(set(names)):
        path = Path(name)
        if path.suffix in {'.zip', '.sqlite', '.log'}:
            continue
        if path.name.startswith('.env') and path.name != '.env.example':
            continue
        if 'vendor' in path.parts or 'node_modules' in path.parts:
            continue
        if name.startswith(('backend/storage/', 'backend/bootstrap/cache/')) and path.name != '.gitignore':
            continue
        if (root / path).is_file():
            out.write(root / path, path.as_posix())
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    assert 'backend/composer.lock' in package.namelist()
    assert 'backend/.env.example' in package.namelist()
    assert 'backend/.env' not in package.namelist()
    assert not any('/vendor/' in n for n in package.namelist())
with zipfile.ZipFile(root / 'DCMCS-professor-handover.zip', 'w', zipfile.ZIP_DEFLATED) as out:
    for path in sorted((root / 'professor_handover').iterdir()):
        if path.is_file():
            out.write(path, 'professor_handover/' + path.name)
print(f'Created {archive}')
