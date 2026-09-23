"""Check the upload-only homepage and API paths through the PHP entry point."""
import os
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
entry = (root / 'backend/public/index.php').as_posix()
env = dict(os.environ, APP_ENV='testing', SESSION_DRIVER='array', CACHE_STORE='array')
cases = [
    ('/dept_comp/public/', '/dept_comp/public/index.php', 'flutter_bootstrap.js'),
    ('/dept_comp/public/index.php', '/dept_comp/public/index.php', 'flutter_bootstrap.js'),
    ('/up', '/index.php', '"status":"ok"'),
    ('/api/profile', '/index.php', 'Unauthenticated'),
]
for uri, script, expected in cases:
    code = (
        "$_SERVER['REQUEST_METHOD']='GET';"
        f"$_SERVER['REQUEST_URI']='{uri}';"
        f"$_SERVER['SCRIPT_NAME']='{script}';"
        f"$_SERVER['PHP_SELF']='{script}';"
        f"$_SERVER['SCRIPT_FILENAME']='{entry}';"
        "$_SERVER['HTTP_ACCEPT']='application/json';"
        f"require '{entry}';"
    )
    result = subprocess.run(['C:/xampp/php/php.exe', '-r', code], cwd=root / 'backend',
                            env=env, text=True, capture_output=True, timeout=30)
    assert result.returncode == 0 and expected in result.stdout, (uri, result.stdout, result.stderr)
    if '/api/' in uri:
        assert 'flutter_bootstrap.js' not in result.stdout
    print(uri + ': PASS')
