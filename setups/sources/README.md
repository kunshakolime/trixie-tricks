# Debian 13 (trixie) apt sources

## Install

Full setup (writes deb822 sources, fetches keys, installs `apt-sources`, runs interactive picker):

```bash
sudo curl -fsSL https://raw.githubusercontent.com/kunshakolime/trixie-tricks/main/setups/sources/setup-sources.sh -o /tmp/setup-sources.sh && sudo bash /tmp/setup-sources.sh
```

Or install just `apt-sources`:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/kunshakolime/trixie-tricks/main/setups/sources/apt-sources.sh -o /usr/local/bin/apt-sources && sudo chmod +x /usr/local/bin/apt-sources
```

Or from a local clone:

```bash
sudo ./setup-sources.sh
```

## `apt-sources`

```bash
apt-sources                 # interactive checklist
apt-sources list            # show state
apt-sources enable forky    # on
apt-sources disable wine    # off
apt-sources toggle vscode   # flip
```

Works with deb822 (`*.sources`) and one-line (`sources.list`, `*.list`). First change backed up as `<file>.apt-sources.bak`. Run `apt-get update` after.

## Repos

Opt-in repos are written with `Enabled: no`. Each source file is also in this folder for manual use (copy to `/etc/apt/sources.list.d/`).

| Repo | File | Install |
|---|---|---|
| trixie | `debian.sources` / `sources.list` | base system (skipped if present) |
| forky | `forky.sources`, `forky.pref` | `sudo apt -t forky install <pkg>` |
| google | `google-chrome.sources` | `sudo apt install google-chrome-stable` |
| wine | `wine.sources` | `sudo dpkg --add-architecture i386 && sudo apt install --install-recommends wine-devel` |
| vscode | `vscode.sources` | `sudo apt install code` |
| firefox | `firefox.sources` | `sudo apt install firefox` |
| virtualbox | `virtualbox.sources` | `sudo apt search virtualbox` |

forky is pinned priority 100 (`/etc/apt/preferences.d/forky`). Signing keys live in `/etc/apt/keyrings/`.
