#!/bin/bash
# после веб-экспорта: вставить coi-serviceworker (включает threads на GitHub Pages)
set -e
cd "$(dirname "$0")/.."
if ! grep -q coi-serviceworker docs/index.html; then
  sed -i '' 's|<head>|<head><script src="coi-serviceworker.js"></script>|' docs/index.html
  echo "coi-serviceworker подключён"
else
  echo "coi уже подключён"
fi
