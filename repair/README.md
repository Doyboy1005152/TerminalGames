# Repair an existing Terminal Games connection

This is **not a reinstall**. Close Terminal Games, run the repair for your device, then reopen your usual shortcut.

- [Mac repair](https://github.com/Doyboy1005152/TerminalGames/raw/refs/heads/main/repair/repair-mac.command)
- [Windows repair](https://github.com/Doyboy1005152/TerminalGames/raw/refs/heads/main/repair/repair-windows.bat)
- [Linux repair](https://github.com/Doyboy1005152/TerminalGames/raw/refs/heads/main/repair/repair-linux.sh)

On Mac, you can instead paste this into Terminal after closing the game:

```sh
curl --fail --location --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Doyboy1005152/TerminalGames/main/repair/repair.py -o /tmp/terminal-games-connection-repair.py && python3 /tmp/terminal-games-connection-repair.py
```

The repair checks both game connections before changing files. It locates standard existing installations, backs up the affected files, and changes only the Main/Dev connection addresses and the address lookup module. It does not replace the game version, accounts, passwords, settings, saves, music, or shortcuts, and it does not create another installation.

Current modular versions also gain a lookup at the start of each launch using this repository's `connection.json`, an independent HTTPS mirror, and a saved local copy. Future address changes can then be published here without another repair. The newest valid dated directory is preferred. If both directories are unavailable, the game uses its saved copy, then its installed connection addresses. This is not an uptime guarantee; the game service and directory still need to be available and maintained.

Very old flat-layout versions receive the address repair only; use **Check for updates** after reconnecting. Custom installations can run `python3 repair.py "/path/to/Terminal Games/Dependencies"`.

The old temporary addresses have expired. Already disconnected copies have no way to receive this change automatically, so each affected device needs this one-time repair or the current installer. You do not need a new account.

For maintainers: keep both entries in `connection.json` current and verify HTTPS health and WebSocket connectivity before publishing address changes. Do not put credentials in this public file. Changing the directory alone cannot repair clients that do not yet contain the lookup module.

## Recovery safeguards release

Public 5.5.15 and Dev 5.5.16 add persistent rollback for subsequent updates. Once an update has been made with the new updater, the game folder contains `recover-last-update.py` and **RECOVER LAST UPDATE** launchers. Close all game windows before restoring. The rollback keeps a previous file snapshot on your device and blocks reinstalling that exact failed package; it does not restore server-side progress. These files are not retroactively available on older copies.
