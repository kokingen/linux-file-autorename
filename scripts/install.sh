#!/bin/bash
# 安装 build/ 或当前目录里的补丁版 deb，并锁定版本防止被系统更新覆盖
set -e
D=${1:-$(cd "$(dirname "$0")/.." && pwd)/build}
debs=()
for p in caja caja-common libcaja-extension1 gir1.2-caja-2.0 nemo nemo-data libnemo-extension1 gir1.2-nemo-3.0; do
  f=$(ls "$D"/${p}_*autorename*.deb 2>/dev/null | tail -1); [ -n "$f" ] && debs+=("$f") && hold+=("$p")
done
[ ${#debs[@]} -gt 0 ] || { echo "在 $D 没找到 deb"; exit 1; }
sudo apt-get install -y --allow-downgrades "${debs[@]}"
sudo apt-mark hold "${hold[@]}"
caja -q 2>/dev/null || true; nemo -q 2>/dev/null || true
pgrep -x nemo-desktop >/dev/null && { pkill -x nemo-desktop; nohup nemo-desktop >/dev/null 2>&1 & }
echo "已安装：${hold[*]}"
