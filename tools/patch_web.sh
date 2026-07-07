#!/bin/bash
# после веб-экспорта: снять регистрацию coi-serviceworker у старых клиентов (threads откатили)
set -e
cd "$(dirname "$0")/.."
if ! grep -q 'coi-unregister' docs/index.html; then
  sed -i '' 's|<head>|<head><script id="coi-unregister">if("serviceWorker" in navigator){navigator.serviceWorker.getRegistrations().then(function(rs){rs.forEach(function(r){if(r.active\&\&r.active.scriptURL.indexOf("coi-serviceworker")>=0){r.unregister();}});});}</script>|' docs/index.html
  echo "coi-unregister вставлен"
fi
