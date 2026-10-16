# appended tests (sourced at end of suite before cleanup) ; S1/S2 = copy/another-copy tags
reset; echo n >"$H/a/m.txt"; echo o >"$H/b/m.txt"; echo n >"$H/a/v1.2.3.txt"; echo o >"$H/b/v1.2.3.txt"
r=$(run copy "$H/b" "$H/a/m.txt" "$H/a/v1.2.3.txt")
ok "17 one-letter + dotted names" '[ $r = 0 ] && [ -f "$H/b/m${S1}.txt" ] && [ $(ls "$H/b"|wc -l) = 4 ]'
ls "$H/b" | sed "s/^/      /"
reset; echo n >"$H/a/报告${S1}.pdf"; echo o >"$H/b/报告${S1}.pdf"
r=$(run copy "$H/b" "$H/a/报告${S1}.pdf")
ok "18 name already has copy tag" '[ $r = 0 ] && [ $(ls "$H/b"|wc -l) = 2 ] && [ "$(c "$H/b/报告${S1}.pdf")" = o ]'
reset; mkdir -p "$H/a/p/q/r" "$H/b/p/q/r"; echo n >"$H/a/p/q/r/deep.txt"; echo o >"$H/b/p/q/r/deep.txt"
r=$(run move "$X/b" "$H/a/p"); r2=$(run move "$H/b" "$X/b/p")
ok "19 deep merge move across fs twice" '[ $r = 0 ] && [ $r2 = 0 ] && [ "$(c "$H/b/p/q/r/deep.txt")" = o ] && [ "$(c "$H/b/p/q/r/deep${S1}.txt")" = n ] && [ ! -e "$H/a/p" ] && [ ! -e "$X/b/p" ]'
reset; mkdir -p "$H/a/e" "$H/b/e"; echo n >"$H/a/e/x"; chmod 700 "$H/b/e"; setfattr -n user.k -v keep "$H/b/e" 2>/dev/null
r=$(run move "$H/b" "$H/a/e")
ok "20 move into EMPTY same-name dir keeps it" '[ $r = 0 ] && [ "$(c "$H/b/e/x")" = n ] && [ "$(stat -c %a "$H/b/e")" = 700 ] && [ ! -e "$H/a/e" ]'
reset; mkdir -p "$H/a/e2" "$X/b/e2"; echo n >"$H/a/e2/x"; echo o >"$X/b/e2/y"
r=$(run move "$X/b" "$H/a/e2")
ok "21 cross-fs move dir merge keeps old" '[ $r = 0 ] && [ "$(c "$X/b/e2/x")$(c "$X/b/e2/y")" = no ] && [ ! -e "$H/a/e2" ]'
