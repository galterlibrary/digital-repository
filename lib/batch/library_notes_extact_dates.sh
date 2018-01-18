#!/bin/bash
# For extracting dates from Library notes not on the HTTP server
for f in *.pdf; do
  echo $f
  pdftotext $f $f.txt >/dev/null 2>&1
  echo $(sed -n '/NEW SERIES #[0-9]\+/{n;p;}' $f.txt | grep -E ' [0-9]{4}' ||
    grep  -A2 -i -E 'NEW SERIES .*[0-9]+' $f.txt |grep -E '[0-9]{4}') > $f.date
  cat $f.date
done
