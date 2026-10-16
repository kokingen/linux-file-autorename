#!/bin/bash
# caja-autorename test suite. Usage: suite.sh /path/to/test-ar
T=${1:-$HOME/caja-autorename/test-ar}
export DISPLAY=:0 XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
H=$HOME/.ar-test; X=/tmp/ar-test   # H on ext4 (home), X on tmpfs -> cross-fs
export LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8
S1="（副本）"; S2="（另一个副本）"
pass=0; fail=0
ok(){ if eval "$2"; then echo "PASS $1"; pass=$((pass+1)); else echo "FAIL $1   [$2]"; fail=$((fail+1)); fi; }
c(){ cat "$1" 2>/dev/null; }
reset(){ rm -rf "$H" "$X"; mkdir -p "$H/a" "$H/b" "$X/b"; }
run(){ timeout 30 "$T" "$@" >/dev/null 2>>/tmp/ar-err; echo $?; }
: > /tmp/ar-err

reset; echo new >"$H/a/报告.pdf"; echo old >"$H/b/报告.pdf"
r=$(run copy "$H/b" "$H/a/报告.pdf")
ok "01 copy conflict exit" '[ $r = 0 ]'
ok "01 old untouched" '[ "$(c "$H/b/报告.pdf")" = old ]'
ok "01 new as 副本" '[ "$(c "$H/b/报告（副本）.pdf")" = new ]'
ok "01 source kept" '[ -f "$H/a/报告.pdf" ]'
run copy "$H/b" "$H/a/报告.pdf" >/dev/null; run copy "$H/b" "$H/a/报告.pdf" >/dev/null
ok "02 2nd copy" '[ -f "$H/b/报告（另一个副本）.pdf" ]'
ok "02 3rd copy" '[ $(ls "$H/b" | wc -l) = 4 ]'
ok "02 nothing overwritten" '[ "$(c "$H/b/报告.pdf")" = old ]'

reset; for f in x.txt y.txt z.txt; do echo N$f >"$H/a/$f"; done; echo Ox >"$H/b/x.txt"; echo Oz >"$H/b/z.txt"
r=$(run copy "$H/b" "$H/a/x.txt" "$H/a/y.txt" "$H/a/z.txt")
ok "03 multi exit" '[ $r = 0 ]'
ok "03 multi result" '[ "$(cd "$H/b"; ls | LC_ALL=C sort | tr "\n" "|")" = "x.txt|x（副本）.txt|y.txt|z.txt|z（副本）.txt|" ]'
ok "03 olds kept" '[ "$(c "$H/b/x.txt")$(c "$H/b/z.txt")" = OxOz ]'

reset; mkdir -p "$H/a/资料/sub" "$H/b/资料/sub"; echo n1 >"$H/a/资料/1.txt"; echo o1 >"$H/b/资料/1.txt"; echo n2 >"$H/a/资料/2.txt"; echo ns >"$H/a/资料/sub/s.txt"; echo os >"$H/b/资料/sub/s.txt"; echo keep >"$H/b/资料/only-old.txt"
r=$(run copy "$H/b" "$H/a/资料")
ok "04 folder merge exit" '[ $r = 0 ]'
ok "04 no renamed folder" '[ ! -e "$H/b/资料（副本）" ]'
ok "04 inner conflict renamed" '[ "$(c "$H/b/资料/1.txt")$(c "$H/b/资料/1（副本）.txt")" = o1n1 ]'
ok "04 new file added" '[ "$(c "$H/b/资料/2.txt")" = n2 ]'
ok "04 nested conflict" '[ "$(c "$H/b/资料/sub/s.txt")$(c "$H/b/资料/sub/s（副本）.txt")" = osns ]'
ok "04 old-only kept" '[ -f "$H/b/资料/only-old.txt" ]'

reset; echo new >"$H/a/m.txt"; echo old >"$H/b/m.txt"
r=$(run move "$H/b" "$H/a/m.txt")
ok "05 move same-fs" '[ $r = 0 ] && [ ! -e "$H/a/m.txt" ] && [ "$(c "$H/b/m.txt")$(c "$H/b/m（副本）.txt")" = oldnew ]'

reset; mkdir -p "$H/a/d" "$H/b/d"; echo n >"$H/a/d/f"; echo o >"$H/b/d/f"; echo n2 >"$H/a/d/g"
r=$(run move "$H/b" "$H/a/d")
ok "06 move folder merge" '[ $r = 0 ] && [ "$(c "$H/b/d/f")$(c "$H/b/d/f（副本）")$(c "$H/b/d/g")" = onn2 ] && [ ! -e "$H/a/d" ]'

reset; echo new >"$H/a/c.txt"; echo old >"$X/b/c.txt"; mkdir -p "$H/a/cd" "$X/b/cd"; echo n >"$H/a/cd/f"; echo o >"$X/b/cd/f"
r=$(run copy "$X/b" "$H/a/c.txt" "$H/a/cd")
ok "07 cross-fs copy" '[ $r = 0 ] && [ "$(c "$X/b/c.txt")$(c "$X/b/c（副本）.txt")" = oldnew ] && [ "$(c "$X/b/cd/f")$(c "$X/b/cd/f（副本）")" = on ]'
r=$(run move "$X/b" "$H/a/c.txt")
ok "08 cross-fs move" '[ $r = 0 ] && [ ! -e "$H/a/c.txt" ] && [ "$(c "$X/b/c（另一个副本）.txt")" = new ]'

reset; echo file >"$H/a/same"; mkdir "$H/b/same"; echo in >"$H/b/same/x"
r=$(run copy "$H/b" "$H/a/same")
ok "09 file onto dir" '[ $r = 0 ] && [ -d "$H/b/same" ] && [ "$(c "$H/b/same/x")" = in ] && [ "$(c "$H/b/same（副本）")" = file ]'
reset; mkdir "$H/a/same2"; echo in >"$H/a/same2/x"; echo file >"$H/b/same2"
r=$(run copy "$H/b" "$H/a/same2")
ok "10 dir onto file" '[ $r = 0 ] && [ "$(c "$H/b/same2")" = file ] && [ "$(c "$H/b/same2（副本）/x")" = in ]'

reset; for f in .bashrc 备份.tar.gz noext "a b c.txt"; do echo n >"$H/a/$f"; echo o >"$H/b/$f"; done
r=$(run copy "$H/b" "$H/a/.bashrc" "$H/a/备份.tar.gz" "$H/a/noext" "$H/a/a b c.txt")
ok "11 odd names exit" '[ $r = 0 ]'
ok "11 odd names count" '[ $(ls -A "$H/b" | wc -l) = 8 ]'
ok "11 odd names olds" '[ "$(cat "$H/b/.bashrc" "$H/b/备份.tar.gz" "$H/b/noext" "$H/b/a b c.txt" | tr -d "\n")" = oooo ]'
ls -A "$H/b" | sed "s/^/      /"

reset; echo x >"$H/a/dup.txt"
r=$(run copy "$H/a" "$H/a/dup.txt")
ok "12 duplicate in same folder" '[ $r = 0 ] && [ -f "$H/a/dup（副本）.txt" ] && [ $(ls "$H/a"|wc -l) = 2 ]'

reset; echo new >"$H/a/k.txt"; echo old >"$H/b/k.txt"
r=$(CAJA_NO_AUTORENAME=1 run copy "$H/b" "$H/a/k.txt")
ok "13 opt-out shows dialog (times out)" '[ $r = 3 ] && [ "$(c "$H/b/k.txt")" = old ] && [ $(ls "$H/b"|wc -l) = 1 ]'

reset; mkdir -p "$H/a/big"; for i in $(seq 1 300); do echo n$i >"$H/a/big/f$i"; done; mkdir -p "$H/b/big"; for i in $(seq 1 300 ); do [ $((i%2)) = 0 ] && echo o$i >"$H/b/big/f$i"; done
r=$(run copy "$H/b" "$H/a/big")
ok "14 300 files, 150 conflicts" '[ $r = 0 ] && [ $(ls "$H/b/big" | wc -l) = 450 ] && [ "$(c "$H/b/big/f2")$(c "$H/b/big/f2（副本）")" = o2n2 ]'

reset; echo new >"$H/a/ro.txt"; echo old >"$H/b/ro.txt"; chmod 444 "$H/b/ro.txt"
r=$(run copy "$H/b" "$H/a/ro.txt")
ok "15 read-only existing file" '[ $r = 0 ] && [ "$(c "$H/b/ro.txt")$(c "$H/b/ro（副本）.txt")" = oldnew ]'
chmod 644 "$H/b/ro.txt"

reset; ln -s /etc/hostname "$H/a/lnk"; echo old >"$H/b/lnk"
r=$(run copy "$H/b" "$H/a/lnk")
ok "16 symlink conflict" '[ $r = 0 ] && [ "$(c "$H/b/lnk")" = old ] && [ -L "$H/b/lnk（副本）" ]'

. "$(dirname "$0")/extra.sh"
rm -rf "$H" "$X"
echo "TOTAL pass=$pass fail=$fail"
