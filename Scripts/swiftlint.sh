#!/bin/bash
# SwiftLint runner script
# Usage:
#   ./Scripts/swiftlint.sh          # lint (warning only)
#   ./Scripts/swiftlint.sh --fix    # auto-fix correctable violations
#   ./Scripts/swiftlint.sh --strict # treat warnings as errors

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_TOOLS_DIR="${REPO_ROOT}/Dependencies/BuildTools"
SWIFTLINT_BIN="${BUILD_TOOLS_DIR}/.build/release/swiftlint"

# Build SwiftLint if binary doesn't exist
if [ ! -f "${SWIFTLINT_BIN}" ]; then
    echo "==> Building SwiftLint (first run may take a few minutes)..."
    swift build -c release --package-path "${BUILD_TOOLS_DIR}" --product swiftlint
fi

echo "==> SwiftLint $(${SWIFTLINT_BIN} version)"

cd "${REPO_ROOT}"

if [ "${1:-}" = "--fix" ]; then
    echo "==> Running SwiftLint auto-fix..."
    "${SWIFTLINT_BIN}" --fix --config .swiftlint.yml
    echo "==> Fix complete. Running lint to show remaining issues..."
    "${SWIFTLINT_BIN}" lint --config .swiftlint.yml
elif [ "${1:-}" = "--strict" ]; then
    echo "==> Running SwiftLint (strict mode)..."
    "${SWIFTLINT_BIN}" lint --strict --config .swiftlint.yml
else
    echo "==> Running SwiftLint..."
    "${SWIFTLINT_BIN}" lint --config .swiftlint.yml
fi
