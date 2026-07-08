#!/bin/bash
# Double-click this file to generate the Xcode project and open it.
cd "$(dirname "$0")"

echo "==============================================="
echo "  Hoppity — preparing your Xcode project"
echo "==============================================="
echo ""

XG=""
if command -v xcodegen >/dev/null 2>&1; then
    XG="xcodegen"
    echo "Found XcodeGen already installed."
else
    echo "XcodeGen not found — downloading the official tool (one-time, ~4 MB)…"
    TMP="$(mktemp -d)"
    if ! curl -fL -o "$TMP/xcodegen.zip" "https://github.com/yonaskolb/XcodeGen/releases/download/2.45.4/xcodegen.zip"; then
        echo ""
        echo "ERROR: Could not download XcodeGen (no internet?)."
        echo "Alternative: install Homebrew from https://brew.sh then run:  brew install xcodegen"
        echo ""
        read -p "Press Return to close…"
        exit 1
    fi
    unzip -q "$TMP/xcodegen.zip" -d "$TMP/xg"
    XG="$(find "$TMP/xg" -type f -name xcodegen | head -n1)"
    chmod +x "$XG" 2>/dev/null || true
fi

echo ""
echo "Generating Hoppity.xcodeproj…"
if "$XG" generate; then
    echo ""
    echo "Success! Opening in Xcode…"
    open Hoppity.xcodeproj
    echo ""
    echo "When Xcode opens: wait ~1 min for the Supabase package to load,"
    echo "then press the Run button (▶) with an iPhone simulator selected."
else
    echo ""
    echo "ERROR: project generation failed. Check the messages above."
fi
echo ""
read -p "Press Return to close this window…"
