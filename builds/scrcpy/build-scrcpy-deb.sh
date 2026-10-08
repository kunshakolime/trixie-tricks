#!/usr/bin/env bash
#
# build-scrcpy-deb.sh
#
# Packages the official scrcpy static release into a Debian .deb.
#
# The upstream Linux static release is built with -Dportable=true, so the
# client resolves scrcpy-server, scrcpy.png and disconnected.png relative to
# the *resolved* path of its own executable (/proc/self/exe on Linux). It also
# hardcodes <dir-of-executable>/adb as the adb to run.
#
# So the binary and its data files have to sit in the same directory. To keep
# /usr/bin clean we put everything in /usr/lib/scrcpy/ and expose a single
# symlink at /usr/bin/scrcpy. readlink("/proc/self/exe") resolves that symlink
# back to /usr/lib/scrcpy/scrcpy, so the client finds its data files.
#
# /usr/lib/scrcpy/adb is a symlink to Debian's /usr/bin/adb: the adb bundled
# in the official release is stripped and we depend on the `adb` package
# instead (its command-line interface is stable across versions, so an older
# distro adb works with a newer scrcpy).
#
#   ./build-scrcpy-deb.sh [OUTDIR]      # OUTDIR defaults to $PWD
#
# Bump VERSION below to track the latest release at
# https://github.com/Genymobile/scrcpy/releases

set -euo pipefail

VERSION="5.0.1"
TARBALL="scrcpy-linux-x86_64-v${VERSION}.tar.gz"
TARBALL_URL="https://github.com/Genymobile/scrcpy/releases/download/v${VERSION}/${TARBALL}"
SUMS_URL="https://github.com/Genymobile/scrcpy/releases/download/v${VERSION}/SHA256SUMS.txt"
# Files the static tarball does not ship (it only carries the runtime data).
DATA_BASE="https://raw.githubusercontent.com/Genymobile/scrcpy/v${VERSION}/app/data"

OUTDIR="$PWD"
[ $# -ge 1 ] && OUTDIR="$1"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log() { printf '\n==> %s\n' "$*"; }

command -v curl >/dev/null || { echo "error: curl not found" >&2; exit 1; }
command -v dpkg-deb >/dev/null || { echo "error: dpkg-deb not found" >&2; exit 1; }
command -v dpkg-shlibdeps >/dev/null || { echo "error: dpkg-shlibdeps not found (install dpkg-dev)" >&2; exit 1; }

mkdir -p "$OUTDIR"

log "Downloading official scrcpy v${VERSION} static release"
curl -fsSL -o "$WORK/$TARBALL" "$TARBALL_URL"

log "Verifying SHA-256"
curl -fsSL -o "$WORK/SHA256SUMS.txt" "$SUMS_URL"
EXPECTED="$(awk -v f="$TARBALL" '$2 == f { print $1; exit }' "$WORK/SHA256SUMS.txt")"
[ -n "$EXPECTED" ] || { echo "error: no SHA-256 listed for $TARBALL" >&2; exit 1; }
ACTUAL="$(sha256sum "$WORK/$TARBALL" | cut -d' ' -f1)"
[ "$EXPECTED" = "$ACTUAL" ] || {
    echo "error: checksum mismatch for $TARBALL" >&2
    echo "  expected $EXPECTED" >&2
    echo "  actual   $ACTUAL" >&2
    exit 1
}
echo "  ok  $ACTUAL"

tar -xzf "$WORK/$TARBALL" -C "$WORK"

SRC="$WORK/scrcpy-linux-x86_64-v${VERSION}"
PACKAGE="$WORK/debpkg"
LIBDIR="$PACKAGE/usr/lib/scrcpy"

log "Staging runtime files in /usr/lib/scrcpy (portable layout)"
mkdir -p "$PACKAGE/DEBIAN" "$LIBDIR" "$PACKAGE/usr/bin" "$PACKAGE/usr/share/doc/scrcpy" \
         "$PACKAGE/usr/share/man/man1" \
         "$PACKAGE/usr/share/icons/hicolor/256x256/apps" \
         "$PACKAGE/usr/share/applications" \
         "$PACKAGE/usr/share/bash-completion/completions" \
         "$PACKAGE/usr/share/zsh/site-functions"
install -m 0755 "$SRC/scrcpy" "$LIBDIR/scrcpy"
install -m 0644 "$SRC/scrcpy-server" "$LIBDIR/scrcpy-server"
# The client loads both PNGs from its own directory, not from the icon theme.
install -m 0644 "$SRC/scrcpy.png" "$SRC/disconnected.png" "$LIBDIR/"
# Stripped bundled adb: resolve to Debian's adb at runtime.
ln -s /usr/bin/adb "$LIBDIR/adb"
# /usr/bin/scrcpy -> the real binary, so /proc/self/exe lands in $LIBDIR.
ln -s ../lib/scrcpy/scrcpy "$PACKAGE/usr/bin/scrcpy"

log "Staging man page, copyright and desktop integration"
gzip -9c "$SRC/scrcpy.1" > "$PACKAGE/usr/share/man/man1/scrcpy.1.gz"
cp "$SRC/LICENSE" "$PACKAGE/usr/share/doc/scrcpy/copyright"
# Also publish the icons in the hicolor theme for desktop environments.
install -m 0644 "$SRC/scrcpy.png" "$SRC/disconnected.png" \
    "$PACKAGE/usr/share/icons/hicolor/256x256/apps/"

log "Fetching completions and desktop entries"
for f in bash-completion/scrcpy zsh-completion/_scrcpy scrcpy.desktop scrcpy-console.desktop; do
    case "$f" in
        bash-completion/*) DEST="$PACKAGE/usr/share/bash-completion/completions/" ;;
        zsh-completion/*)  DEST="$PACKAGE/usr/share/zsh/site-functions/" ;;
        *)                 DEST="$PACKAGE/usr/share/applications/" ;;
    esac
    curl -fsSL -o "$DEST/${f##*/}" "$DATA_BASE/$f"
    chmod 0644 "$DEST/${f##*/}"
done

log "Computing shared-library dependencies"
mkdir -p "$WORK/debian"
cat > "$WORK/debian/control" <<'CTL'
Source: scrcpy
Section: net
Priority: optional
Maintainer: Debian 13 build <root@localhost>

Package: scrcpy
Architecture: amd64
Description: Display and control your Android device (screen mirroring)
CTL
DEPS="$(cd "$WORK" && dpkg-shlibdeps -O "$LIBDIR/scrcpy" 2>/dev/null)"
DEPS="${DEPS#shlibs:Depends=}"
DEPS="${DEPS:+$DEPS, }adb (>= 1.0.41)"
echo "Depends: $DEPS"

cat > "$PACKAGE/DEBIAN/control" <<EOF
Package: scrcpy
Version: ${VERSION}
Section: net
Priority: optional
Architecture: amd64
Maintainer: Debian 13 build <root@localhost>
Depends: ${DEPS}
Homepage: https://github.com/Genymobile/scrcpy
Description: Display and control your Android device (screen mirroring)
 A lightweight display and control of Android devices (screen mirroring)
 over USB or Wi-Fi.
 .
 The client, the server and its data files live in /usr/lib/scrcpy, with a
 symlink at /usr/bin/scrcpy.
 .
 The adb bundled in the official static release is stripped; this package
 uses Debian's adb package instead. The adb command-line interface used by
 scrcpy (devices, push, forward, reverse, shell, tcpip, connect) is stable,
 so an older distro adb works.
EOF

log "Building scrcpy_${VERSION}_amd64.deb"
dpkg-deb --build --root-owner-group "$PACKAGE" "$WORK/scrcpy_${VERSION}_amd64.deb"
install -m 0644 "$WORK/scrcpy_${VERSION}_amd64.deb" "$OUTDIR/"
echo
echo "Built: $OUTDIR/scrcpy_${VERSION}_amd64.deb"
echo "Install on Debian 13:  sudo apt install ./scrcpy_${VERSION}_amd64.deb"
