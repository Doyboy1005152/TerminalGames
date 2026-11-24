"""Repair only connection files in existing Terminal Games installations."""
import argparse
import json
import os
import sys
import tempfile
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit
from urllib.request import Request, urlopen

DISCOVERY_URL = 'https://raw.githubusercontent.com/Doyboy1005152/TerminalGames/main/connection.json'
ENDPOINT_MODULE = '"""Resolve both channels once per launch, independently of the game host."""\nfrom app.paths import APP_ROOT\nimport json\nimport threading\nimport os\nimport tempfile\nimport time\nfrom pathlib import Path\nfrom urllib.parse import urlsplit\nfrom urllib.request import Request, urlopen\n\nDISCOVERY_URL = \'https://raw.githubusercontent.com/Doyboy1005152/TerminalGames/main/connection.json\'\nDISCOVERY_MIRRORS = (\'https://blockahacker.com/terminal-games-recovery/connection.json\',)\nCACHE = Path.home() / \'.terminal-games\' / \'connection-cache.json\'\n_urls = {}\n_lock = threading.RLock()\n_discovery_done = False\n\n\ndef _valid(value):\n    if not isinstance(value, str) or len(value) > 512:\n        raise ValueError(\'Invalid game address.\')\n    parsed = urlsplit(value)\n    host = parsed.hostname or \'\'\n    if (parsed.scheme != \'wss\' or parsed.username or parsed.password\n            or parsed.port not in (None, 443) or parsed.path != \'/play\'\n            or parsed.query or parsed.fragment\n            or not (host.endswith(\'.trycloudflare.com\')\n                    or host in (\'games.blockahacker.com\', \'dev-games.blockahacker.com\'))):\n        raise ValueError(\'Invalid secure game address.\')\n    return value\n\n\ndef _discover():\n    global _discovery_done\n    if _discovery_done:\n        return\n    _discovery_done = True\n    sources = (DISCOVERY_URL,) + DISCOVERY_MIRRORS\n    choices = []\n    for source in sources + (None,):\n        try:\n            if source is None:\n                if CACHE.is_symlink():\n                    continue\n                with CACHE.open(\'rb\') as stream:\n                    data = stream.read(4097)\n            else:\n                request = Request(source, headers={\'Cache-Control\': \'no-cache\', \'User-Agent\': \'TerminalGames/1.0\'})\n                with urlopen(request, timeout=4) as response:\n                    data = response.read(4097)\n            if len(data) > 4096:\n                continue\n            packet = json.loads(data)\n            if packet.get(\'schema\') != 1:\n                continue\n            values = {False: _valid(packet[\'main\']), True: _valid(packet[\'dev\'])}\n            revision = packet.get(\'updated_at\', 0)\n            if not isinstance(revision, (int, float)) or not 0 <= revision <= time.time() + 86400:\n                continue\n            choices.append((revision, source, packet, values))\n        except (OSError, ValueError, KeyError, TypeError, AttributeError):\n            continue\n    if choices:\n        revision, source, packet, values = max(choices, key=lambda choice: choice[0])\n        _urls.update(values)\n        if source is not None:\n            _save_cache(packet)\n\n\ndef _save_cache(packet):\n    name = None\n    try:\n        if any(p.is_symlink() for p in (CACHE, *CACHE.parents)):\n            return\n        CACHE.parent.mkdir(parents=True, exist_ok=True)\n        fd, name = tempfile.mkstemp(prefix=\'.connection-\', dir=CACHE.parent)\n        with os.fdopen(fd, \'w\') as stream:\n            json.dump(packet, stream)\n        os.replace(name, CACHE)\n    except OSError:\n        pass\n    finally:\n        if name is not None:\n            try:\n                Path(name).unlink(missing_ok=True)\n            except OSError:\n                pass\n\n\ndef configured_url(dev=False):\n    key = bool(dev)\n    with _lock:\n        _discover()\n        if key not in _urls:\n            from app.platform import resource_recovery\n            path = APP_ROOT / \'config\' / (\'dev-server-url.txt\' if key else \'server-url.txt\')\n            try:\n                value = path.read_text().strip()\n            except OSError as error:\n                if not resource_recovery.exhausted(error):\n                    raise\n                resource_recovery.recover()\n                value = path.read_text().strip()\n            _urls[key] = _valid(value)\n        return _urls[key]\n\n\ndef initialize():\n    from app.platform import resource_recovery\n    resource_recovery.headroom()\n    configured_url(False)\n    if (APP_ROOT / \'config/dev-server-url.txt\').is_file():\n        configured_url(True)\n\n\ndef game_url():\n    from app.interface import ui\n    return configured_url(ui.DEV_RELEASE)\n'


def _addresses_from(directory):
    with urlopen(Request(directory, headers={'Cache-Control': 'no-cache', 'User-Agent': 'TerminalGames/1.0'}), timeout=15) as response:
        data = response.read(4097)
    if len(data) > 4096:
        raise ValueError('Connection directory is too large.')
    packet = json.loads(data)
    if packet.get('schema') != 1:
        raise ValueError('Unknown connection directory format.')
    for key in ('main', 'dev'):
        value = packet[key]
        if not isinstance(value, str):
            raise ValueError('Invalid game address.')
        parsed = urlsplit(value)
        if (parsed.scheme != 'wss' or parsed.username or parsed.password
                or parsed.port not in (None, 443) or parsed.path != '/play'
                or parsed.query or parsed.fragment
                or not ((parsed.hostname or '').endswith('.trycloudflare.com')
                        or parsed.hostname in ('games.blockahacker.com', 'dev-games.blockahacker.com'))):
            raise ValueError('Unrecognized game address.')
        health = urlunsplit(('https', parsed.netloc, '/health', '', ''))
        with urlopen(health, timeout=15) as response:
            if response.status != 200 or response.read(256).strip() != b'Pong room service ready':
                raise ValueError('Game is not ready; no files changed.')
    return packet


def addresses():
    for directory in (DISCOVERY_URL,'https://blockahacker.com/terminal-games-recovery/connection.json'):
        try:
            return _addresses_from(directory)
        except (OSError,ValueError,KeyError,TypeError):
            continue
    raise OSError('Could not verify the game connections. Nothing was changed; try again later.')


def recognized(root):
    marker = root / 'package-id.txt'
    try:
        if marker.exists() and marker.read_text().strip() != 'terminal-games-package-v1':
            return False
        return (root / 'terminal_games.py').is_file() and (
            ((root / 'app/interface/ui.py').is_file() and (root / 'config/server-url.txt').is_file())
            or ((root / 'ui.py').is_file() and (root / 'server-url.txt').is_file()))
    except OSError:
        return False


def candidates(home, explicit=()):
    roots = list(map(Path, explicit))
    if not explicit:
        roots += [home / 'Games/Terminal Games', home / 'Games/Liam-Pong',
                  home / '.local/share/terminal-games/Dependencies']
        local = os.environ.get('LOCALAPPDATA')
        if local:
            roots.append(Path(local) / 'Terminal Games/Dependencies')
        roots += [Path.cwd(), Path.cwd() / 'Dependencies']
        for folder in (home / 'Downloads', home / 'Desktop', home / 'Documents'):
            roots += [folder / 'Terminal Games', folder / 'Terminal Games/Dependencies']
    result = []
    seen = set()
    for root in roots:
        root = root.absolute()
        if root not in seen and recognized(root):
            seen.add(root)
            result.append(root)
        dep = root / 'Dependencies'
        if dep not in seen and recognized(dep):
            seen.add(dep)
            result.append(dep)
    return result


def safe_path(path):
    if any(p.is_symlink() for p in (path, *path.parents)):
        raise ValueError('Linked installation path; no files changed: ' + str(path))


def replace(path, data, mode):
    fd, name = tempfile.mkstemp(prefix='.connection-repair-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
        os.chmod(name, mode)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def repair(root, packet):
    if not recognized(root):
        raise ValueError('Not an existing Terminal Games installation.')
    modular = (root / 'app/platform/server_endpoint.py').is_file()
    config = root / 'config' if (root / 'config/server-url.txt').is_file() else root
    changes = [(config / 'server-url.txt', (packet['main'] + '\n').encode())]
    if (config / 'dev-server-url.txt').is_file():
        changes.append((config / 'dev-server-url.txt', (packet['dev'] + '\n').encode()))
    if modular:
        changes.append((root / 'app/platform/server_endpoint.py', ENDPOINT_MODULE.encode()))
    originals = []
    for path, data in changes:
        safe_path(path)
        original = path.read_bytes()
        if original != data:
            originals.append((path, original, path.stat().st_mode & 0o777, data))
    if not originals:
        return modular
    backup = Path(tempfile.mkdtemp(prefix='connection-repair-backup-', dir=root))
    for path, original, mode, data in originals:
        target = backup / path.relative_to(root)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(original)
    written = []
    try:
        for path, original, mode, data in originals:
            replace(path, data, mode)
            written.append((path, original, mode))
    except BaseException:
        for path, original, mode in reversed(written):
            replace(path, original, mode)
        raise
    return modular


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folders', nargs='*', help='Optional existing game folder')
    args = parser.parse_args()
    roots = candidates(Path.home(), args.folders)
    if not roots:
        raise ValueError('No existing game found. Run this repair from your game folder or pass that folder as an argument.')
    print('Checking Main and Dev before changing anything...', flush=True)
    packet = addresses()
    for root in roots:
        automatic = repair(root, packet)
        print('Repaired: ' + str(root))
        print('Future address lookup enabled.' if automatic else 'Older game repaired. Check for updates in the game next.')
    print('Done. Reopen Terminal Games using your usual shortcut. Accounts, settings, and game version were not replaced.')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print('Repair failed: ' + str(error), file=sys.stderr)
        sys.exit(1)
