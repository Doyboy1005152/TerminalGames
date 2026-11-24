# Terminal Games Connection Repair

For existing copies that cannot connect after the address change. This is a connection repair, not a reinstall or a new account.

1. Close Terminal Games.
2. Download the repair ZIP for your device below and extract it.
3. Run the included repair script, then reopen your usual game shortcut.

- **Mac:** [Download the Mac repair ZIP](https://github.com/Doyboy1005152/TerminalGames/releases/download/repair/Terminal-Games-Repair-Mac.zip), extract it, then double-click `repair-mac.command`. The ZIP preserves permission to run; use it instead of downloading the loose script.
- **Windows:** `Terminal-Games-Repair-Windows.zip` — includes `repair-windows.bat`.
- **Linux:** `Terminal-Games-Repair-Linux.zip` — includes `repair-linux.sh`; run with `sh repair-linux.sh`.

Python 3 is required. Standalone scripts and `repair.py` are also attached. If a Mac script cannot be opened directly, run `bash ` followed by its dragged-in file path in Terminal.

The repair checks the live addresses before changing files, backs up affected files, and preserves your game version, account settings, saves, music, and shortcuts. Modern modular copies gain address discovery for future changes; very old flat-layout copies should use Check for updates after reconnecting.

[Full instructions and source](https://github.com/Doyboy1005152/TerminalGames/tree/main/repair)

This is a separate repair download; the normal game installer release is unchanged.
