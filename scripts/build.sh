#!/bin/bash
# 用法: scripts/build.sh caja|nemo|all
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd); WHAT=${1:-all}; OUT=$ROOT/build
mkdir -p "$OUT"
grep -rqs "^deb-src" /etc/apt/sources.list /etc/apt/sources.list.d/ || \
  sudo sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/*.sources 2>/dev/null || true
sudo apt-get update -qq
sudo apt-get install -y -qq devscripts build-essential dpkg-dev
one(){
  pkg=$1; ver=$(dpkg-query -W -f='${Version}' "$pkg")
  patch=$(ls "$ROOT"/patches/$pkg-*-autorename.patch)
  work=$(mktemp -d); cd "$work"
  sudo apt-get build-dep -y -qq "$pkg"
  apt-get source -qq "$pkg=$ver"
  cd "$(ls -d */ | head -1)"
  patch -p1 < "$patch"
  dch -v "$ver+autorename2" -D "$(lsb_release -cs)" "Auto-rename on name conflict instead of asking." 2>/dev/null
  DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" dpkg-buildpackage -b -uc -us
  cp ../*autorename2*.deb "$OUT"/
  echo "$pkg 编译完成 -> $OUT"
}
[ "$WHAT" = all ] && { one caja; one nemo; } || one "$WHAT"
