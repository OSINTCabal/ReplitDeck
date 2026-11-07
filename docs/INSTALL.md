# Install ReplitDeck

Both distributions use `bash install.sh` from the same source checkout. Linux x86-64 and a graphical desktop session are required. Install the system libraries first.

## Fedora

```bash
sudo dnf install curl python3 binutils tar zstd util-linux procps-ng nss gtk3 alsa-lib mesa-libgbm desktop-file-utils
```

## Debian 13

```bash
sudo apt update
sudo apt install curl python3 binutils tar zstd util-linux procps libnss3 libgtk-3-0t64 libasound2t64 libgbm1 desktop-file-utils
```

ReplitDeck's installer uses Python 3 and does not need a system Node runtime. Node 18 or newer is only needed to run this repository's tests.

## Install and launch

```bash
bash install.sh
~/.local/bin/replitdeck
```

The installation root is `~/.local/opt/replitdeck`. Account data stays in the upstream Replit profile. The installer adds `replitdeck` to `~/.local/bin` and registers the application-menu entry. No system package manager is needed to unpack the app itself.

For disposable tests, set `REPLITDECK_ROOT`, `XDG_BIN_HOME`, `XDG_DATA_HOME`, and `XDG_CONFIG_HOME` to temporary directories. Close the app before changing the installed integration. Ordinary reinstall preserves saved accounts; purge options explicitly remove them.

This installs the desktop integration, not a provider account or subscription. Finish any browser authentication yourself through an upstream-supported method.
