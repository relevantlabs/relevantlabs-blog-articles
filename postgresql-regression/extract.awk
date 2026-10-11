BEGIN {
  FS=" "
}
/^\\set filename/ {
  path=gensub(/^'|'$/, "", "g", $4)
  print path
}
