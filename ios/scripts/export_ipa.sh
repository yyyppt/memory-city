#!/usr/bin/env bash

set -euo pipefail

# Some Xcode asset tools on macOS fail under C.UTF-8 even when the build
# itself is otherwise healthy. Force a locale that Apple's tooling supports.
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_PATH="${WORKSPACE_PATH:-$ROOT_DIR/MemoryCity.xcworkspace}"
PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/MemoryCity.xcodeproj}"
SCHEME="${SCHEME:-MemoryCity}"
CONFIGURATION="${CONFIGURATION:-Release}"
EXPORT_METHOD="${EXPORT_METHOD:-debugging}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/${SCHEME}.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/export}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$ROOT_DIR/build/ExportOptions.plist}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.DerivedDataExport}"
ALLOW_PROVISIONING_UPDATES="${ALLOW_PROVISIONING_UPDATES:-0}"
SKIP_CLEAN="${SKIP_CLEAN:-0}"
TEAM_ID="${TEAM_ID:-}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [options]

Options:
  -s, --scheme NAME            Xcode scheme name. Default: ${SCHEME}
  -c, --configuration NAME     Build configuration. Default: ${CONFIGURATION}
  -m, --method NAME            Export method. Default: ${EXPORT_METHOD}
                               Common values:
                               - debugging        Local install / dev testing
                               - release-testing  Ad Hoc style distribution
                               - app-store-connect Upload to App Store Connect
                               - enterprise       In-house enterprise package
  -t, --team-id ID             Override export Team ID
  -o, --output DIR             Export directory. Default: ${EXPORT_PATH}
  -a, --archive PATH           Archive output path. Default: ${ARCHIVE_PATH}
  -p, --plist PATH             ExportOptions.plist path. Default: ${EXPORT_OPTIONS_PLIST}
  -d, --derived-data PATH      DerivedData path. Default: ${DERIVED_DATA_PATH}
      --allow-provisioning-updates
                               Allow xcodebuild to update signing assets
      --skip-clean
                               Skip the clean step and reuse existing build outputs
  -h, --help                   Show this help

Environment variables with the same names are also supported.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--scheme)
      SCHEME="$2"
      shift 2
      ;;
    -c|--configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    -m|--method)
      EXPORT_METHOD="$2"
      shift 2
      ;;
    -t|--team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    -o|--output)
      EXPORT_PATH="$2"
      shift 2
      ;;
    -a|--archive)
      ARCHIVE_PATH="$2"
      shift 2
      ;;
    -p|--plist)
      EXPORT_OPTIONS_PLIST="$2"
      shift 2
      ;;
    -d|--derived-data)
      DERIVED_DATA_PATH="$2"
      shift 2
      ;;
    --allow-provisioning-updates)
      ALLOW_PROVISIONING_UPDATES=1
      shift
      ;;
    --skip-clean)
      SKIP_CLEAN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Please install Xcode and command line tools first." >&2
  exit 1
fi

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH" "$(dirname "$EXPORT_OPTIONS_PLIST")"
mkdir -p "$DERIVED_DATA_PATH"

if [[ -d "$WORKSPACE_PATH" ]]; then
  CONTAINER_ARGS=(-workspace "$WORKSPACE_PATH")
elif [[ -d "$PROJECT_PATH" ]]; then
  CONTAINER_ARGS=(-project "$PROJECT_PATH")
else
  echo "Neither workspace nor project was found under $ROOT_DIR" >&2
  exit 1
fi

# Some restricted environments can read the workspace but fail to treat it as
# a valid container. Probe it first and fall back to the project when needed.
if [[ "${CONTAINER_ARGS[0]}" == "-workspace" ]]; then
  if ! xcodebuild -list -workspace "$WORKSPACE_PATH" >/dev/null 2>&1; then
    echo "Workspace probe failed, falling back to project container."
    CONTAINER_ARGS=(-project "$PROJECT_PATH")
  fi
fi

cat >"$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>method</key>
  <string>${EXPORT_METHOD}</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>thinning</key>
  <string>&lt;none&gt;</string>
EOF

if [[ -n "$TEAM_ID" ]]; then
  cat >>"$EXPORT_OPTIONS_PLIST" <<EOF
  <key>teamID</key>
  <string>${TEAM_ID}</string>
EOF
fi

cat >>"$EXPORT_OPTIONS_PLIST" <<'EOF'
</dict>
</plist>
EOF

ARCHIVE_CMD=(
  xcodebuild
  "${CONTAINER_ARGS[@]}"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=iOS"
  -derivedDataPath "$DERIVED_DATA_PATH"
  -archivePath "$ARCHIVE_PATH"
)

if [[ "$SKIP_CLEAN" == "1" ]]; then
  ARCHIVE_CMD+=(archive)
else
  ARCHIVE_CMD+=(clean archive)
fi

EXPORT_CMD=(
  xcodebuild
  -exportArchive
  -archivePath "$ARCHIVE_PATH"
  -exportPath "$EXPORT_PATH"
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
)

if [[ "$ALLOW_PROVISIONING_UPDATES" == "1" ]]; then
  ARCHIVE_CMD+=(-allowProvisioningUpdates)
  EXPORT_CMD+=(-allowProvisioningUpdates)
fi

echo "==> Archiving ${SCHEME} (${CONFIGURATION})"
"${ARCHIVE_CMD[@]}"

echo "==> Exporting IPA using method: ${EXPORT_METHOD}"
"${EXPORT_CMD[@]}"

IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print -quit)"

if [[ -z "$IPA_PATH" ]]; then
  echo "Export finished, but no .ipa file was found in $EXPORT_PATH" >&2
  exit 1
fi

echo
echo "IPA ready:"
echo "$IPA_PATH"
