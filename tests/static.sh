#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
omarchy_path="${OMARCHY_PATH:-/usr/share/omarchy}"
qmllint_bin="${QMLLINT:-/usr/lib/qt6/bin/qmllint}"
qmltestrunner_bin="${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}"
import_root="$(mktemp -d)"

cleanup() {
  rm -rf -- "$import_root"
}
trap cleanup EXIT

omarchy plugin validate "$plugin_dir"
jq -e '
  .schemaVersion == 1
  and .id == "io.github.ctl0v0.kalm"
  and (.kinds | index("service")) != null
  and (.kinds | index("bar-widget")) != null
  and .entryPoints.service == "Service.qml"
  and .entryPoints.barWidget == "BarWidget.qml"
' "$plugin_dir/manifest.json" >/dev/null

ln -s "$omarchy_path/shell" "$import_root/qs"
"$qmllint_bin" -I "$import_root" --missing-property disable --uncreatable-type disable \
  "$plugin_dir/BarWidget.qml" \
  "$plugin_dir/Panel.qml" \
  "$plugin_dir/Service.qml" \
  "$plugin_dir/BreathBloom.qml"

env -u DISPLAY -u WAYLAND_DISPLAY -u QT_QPA_PLATFORMTHEME -u GDK_BACKEND \
  QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  "$qmltestrunner_bin" -input "$plugin_dir/tests" -o -,txt

printf '%s\n' 'Kalm validation and tests passed.'
