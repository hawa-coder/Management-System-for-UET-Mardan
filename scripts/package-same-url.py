"""Package the website and homepage route for the existing university backend."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
site = root / 'backend/public/site'
assert (site / 'index.html').is_file(), 'Build the website first.'
assert '<base href="/dept_comp/public/site/">' in (site / 'index.html').read_text(encoding='utf-8')
assert 'https://uetmardan.edu.pk/dept_comp/public/api' in (site / 'main.dart.js').read_text(encoding='utf-8')
output = root / 'website-update-for-sir.zip'
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(site.rglob('*')):
        if path.is_file():
            archive.write(path, path.relative_to(root / 'backend').as_posix())
    archive.write(root / 'backend/public/index.php', 'public/index.php')
    archive.write(root / 'docs/SAME_URL_SETUP.txt', 'READ_ME_FIRST.txt')
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert 'public/site/index.html' in archive.namelist()
    assert 'routes/web.php' not in archive.namelist()
    assert 'public/index.php' in archive.namelist()
    assert '.env' not in archive.namelist()
print(f'Created {output}')
