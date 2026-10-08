# scrcpy

Display and control your Android device (screen mirroring) over USB or Wi-Fi.

## Install

```bash
wget -c -O /tmp/scrcpy_5.0.1_amd64.deb https://github.com/kunshakolime/trixie-tricks/releases/download/scrcpy-5.0.1/scrcpy_5.0.1_amd64.deb && sudo apt install /tmp/scrcpy_5.0.1_amd64.deb
```

Depends on Debian's `adb`.

## Layout

Data files sit next to the real binary because the release is built portable.

```
/usr/lib/scrcpy/scrcpy              # real binary
/usr/lib/scrcpy/scrcpy-server
/usr/lib/scrcpy/{scrcpy,disconnected}.png
/usr/lib/scrcpy/adb -> /usr/bin/adb
/usr/bin/scrcpy -> ../lib/scrcpy/scrcpy
```

Also installed: man page, bash/zsh completions, desktop entries, hicolor icons.

## Rebuild

```bash
./build-scrcpy-deb.sh [OUTDIR]
```

Bump `VERSION` in `build-scrcpy-deb.sh` to track the latest tag from
<https://github.com/Genymobile/scrcpy/releases>.

## Alternative: official release tarball

Installs into `/opt/scrcpy/` instead, no deb. Same layout rule: data files must
sit next to the binary.

```bash
sudo bash -c 'V=5.0.1; command -v adb >/dev/null || apt install -y adb; mkdir -p /opt/scrcpy && curl -fsSL https://github.com/Genymobile/scrcpy/releases/download/v${V}/scrcpy-linux-x86_64-v${V}.tar.gz | tar -xz --strip-components=1 -C /opt/scrcpy scrcpy-linux-x86_64-v${V}/scrcpy scrcpy-linux-x86_64-v${V}/scrcpy-server scrcpy-linux-x86_64-v${V}/scrcpy.png scrcpy-linux-x86_64-v${V}/disconnected.png && chmod +x /opt/scrcpy/scrcpy && ln -sf /usr/bin/adb /opt/scrcpy/adb && ln -sf /opt/scrcpy/scrcpy /usr/local/bin/scrcpy && scrcpy --version'
```
