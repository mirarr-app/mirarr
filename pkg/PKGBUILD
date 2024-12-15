# Maintainer: mirarrapp <iknowarch@proton.me>
pkgname=mirarr-bin
pkgver=1.7.0
pkgrel=1
pkgdesc="A Flutter-based movie and TV show app"
arch=('x86_64')
url="https://github.com/mirarr-app/mirarr"
license=('MIT')
depends=('gtk3')
provides=('mirarr')
conflicts=('mirarr')

source=("$pkgname-$pkgver.zip::https://github.com/mirarr-app/mirarr/releases/download/$pkgver/mirarr.zip")
sha256sums=('SKIP')

package() {
    install -dm755 "$pkgdir/opt/mirarr"
    cp -r "$srcdir"/* "$pkgdir/opt/mirarr/"
    
    # Create executable
    install -dm755 "$pkgdir/usr/bin"
    cat > "$pkgdir/usr/bin/mirarr" << EOF
#!/bin/sh
exec /opt/mirarr/Mirarr "\$@"
EOF
    chmod +x "$pkgdir/usr/bin/mirarr"

    # Desktop file
    install -Dm644 /dev/stdin "$pkgdir/usr/share/applications/mirarr.desktop" << EOF
[Desktop Entry]
Name=Mirarr
Comment=Movie and TV show app
Exec=mirarr
Icon=/opt/mirarr/data/flutter_assets/assets/images/duckie.png
Terminal=false
Type=Application
Categories=Multimedia;
EOF
}