#!/bin/bash
# 恢复官方版 Caja / Nemo
set -e
pk=(); for p in caja caja-common libcaja-extension1 gir1.2-caja-2.0 nemo nemo-data libnemo-extension1 gir1.2-nemo-3.0; do
  v=$(dpkg-query -W -f='${Version}' $p 2>/dev/null) || continue
  case $v in *autorename*) pk+=("$p=${v%+autorename*}");; esac
done
[ ${#pk[@]} -gt 0 ] || { echo "没有安装补丁版"; exit 0; }
sudo apt-mark unhold "${pk[@]%%=*}"
sudo apt-get install -y --reinstall --allow-downgrades "${pk[@]}"
caja -q 2>/dev/null || true; nemo -q 2>/dev/null || true
pgrep -x nemo-desktop >/dev/null && { pkill -x nemo-desktop; nohup nemo-desktop >/dev/null 2>&1 & }
echo "已恢复官方版：${pk[*]}"
