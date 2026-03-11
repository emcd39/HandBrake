#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
BUILD_DIR="$(pwd)/build"
PACKAGE_DIR="$(pwd)/packaging/handbrake-rk3588_${VERSION}_arm64"
ARTIFACTS_DIR="${2:-$(pwd)/artifacts}"
GTK_ARTIFACT_DIR="$ARTIFACTS_DIR/handbrake-gtk-rkmpp-arm64/build"
CLI_ARTIFACT_DIR="$ARTIFACTS_DIR/handbrake-cli-rkmpp-arm64/build"

rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/DEBIAN"
mkdir -p "$PACKAGE_DIR/usr/bin"
mkdir -p "$PACKAGE_DIR/usr/share/applications"
mkdir -p "$PACKAGE_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PACKAGE_DIR/usr/lib/handbrake"

if [ -f "$GTK_ARTIFACT_DIR/gtk/src/ghb" ]; then
    cp "$GTK_ARTIFACT_DIR/gtk/src/ghb" "$PACKAGE_DIR/usr/bin/ghb"
    chmod 755 "$PACKAGE_DIR/usr/bin/ghb"
fi

if [ -f "$CLI_ARTIFACT_DIR/HandBrakeCLI" ]; then
    cp "$CLI_ARTIFACT_DIR/HandBrakeCLI" "$PACKAGE_DIR/usr/bin/HandBrakeCLI"
    chmod 755 "$PACKAGE_DIR/usr/bin/HandBrakeCLI"
fi

if [ -f "$PACKAGE_DIR/usr/bin/ghb" ]; then
cat > "$PACKAGE_DIR/usr/share/applications/handbrake.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=HandBrake
GenericName=Video Transcoder
Comment=Convert video from nearly any format to a selection of modern codecs
Exec=ghb
Icon=handbrake
Terminal=false
Type=Application
Categories=AudioVideo;Video;
MimeType=video/x-msvideo;video/x-matroska;video/mp4;video/quicktime;
EOF
fi

cp "$(pwd)/packaging/debian/control" "$PACKAGE_DIR/DEBIAN/control"
sed -i "s/Version: .*/Version: ${VERSION}/" "$PACKAGE_DIR/DEBIAN/control"

cat > "$PACKAGE_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
groupadd -f mpp 2>/dev/null || true
usermod -aG mpp $SUDO_USER 2>/dev/null || true
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger 2>/dev/null || true
EOF
chmod 755 "$PACKAGE_DIR/DEBIAN/postinst"

dpkg-deb --build "$PACKAGE_DIR"
echo "Package created: ${PACKAGE_DIR}.deb"
