#!/bin/bash
# Build and package PastScreen for App Store submission
# Usage: ./scripts/appstore_release.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}PastScreen App Store Release Builder${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Read version and build from Info.plist
VERSION=$(defaults read "$(pwd)/PastScreen/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
BUILD=$(defaults read "$(pwd)/PastScreen/Info.plist" CFBundleVersion 2>/dev/null || echo "unknown")
MIN_OS=$(defaults read "$(pwd)/PastScreen/Info.plist" LSMinimumSystemVersion 2>/dev/null || echo "14.0")

echo -e "${GREEN}Version:${NC} $VERSION (build $BUILD)"
echo -e "${GREEN}Minimum macOS:${NC} $MIN_OS"
echo ""

# Confirm with user
read -p "Continue with App Store build? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Build cancelled.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Cleaning previous builds...${NC}"
xcodebuild clean \
    -project PastScreen.xcodeproj \
    -scheme PastScreen \
    -configuration Release

echo ""
echo -e "${BLUE}Step 2: Creating archive for App Store...${NC}"
xcodebuild archive \
    -project PastScreen.xcodeproj \
    -scheme PastScreen \
    -configuration Release \
    -archivePath "build/PastScreen.xcarchive" \
    -destination "generic/platform=macOS" \
    | xcpretty || true

if [ ! -d "build/PastScreen.xcarchive" ]; then
    echo -e "${RED}❌ Archive creation failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Archive created successfully!${NC}"
echo -e "Location: $(pwd)/build/PastScreen.xcarchive"
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "1. Open Xcode Organizer:"
echo -e "   ${GREEN}Window → Organizer${NC}"
echo ""
echo "2. Select the PastScreen v$VERSION archive"
echo ""
echo "3. Click 'Distribute App'"
echo ""
echo "4. Choose 'App Store Connect'"
echo ""
echo "5. Follow prompts to upload"
echo ""
echo "6. Go to App Store Connect web interface:"
echo -e "   ${GREEN}https://appstoreconnect.apple.com${NC}"
echo ""
echo "7. Submit for review with notes:"
echo "   - Guideline 2.4.5(i): User selects save folder via NSOpenPanel"
echo "   - Guideline 2.1: English localization only, comprehensive privacy policy"
echo ""
echo -e "${GREEN}✅ Build ready for App Store submission!${NC}"
