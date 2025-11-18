#!/bin/bash

# Script de build pour l'App Store
# Usage: ./scripts/build_appstore.sh

set -e  # Exit on error

echo "🏗️  [BUILD] Starting App Store build process..."

# Couleurs pour les logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="PastScreen"
SCHEME="PastScreen"
ARCHIVE_PATH="$HOME/Desktop/PastScreen-AppStore.xcarchive"
EXPORT_PATH="$HOME/Desktop/PastScreen-AppStore"

echo -e "${BLUE}📦 Configuration:${NC}"
echo "  - Scheme: $SCHEME"
echo "  - Archive: $ARCHIVE_PATH"
echo "  - Export: $EXPORT_PATH"
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "$PROJECT_NAME.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Erreur: Fichier projet non trouvé${NC}"
    echo "   Assurez-vous d'exécuter ce script depuis la racine du projet"
    exit 1
fi

# Nettoyer les builds précédents
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
xcodebuild clean \
    -scheme "$SCHEME" \
    -configuration Release

# Créer l'archive avec le flag APPSTORE
echo -e "${BLUE}📦 Creating archive with App Store configuration...${NC}"
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    OTHER_SWIFT_FLAGS="-D APPSTORE" \
    INFOPLIST_FILE="PastScreen/Info-AppStore.plist" \
    CODE_SIGN_ENTITLEMENTS="PastScreenAppStore.entitlements" \
    SPARKLE_ENABLED=NO

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Archive creation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive created successfully!${NC}"
echo ""

# Créer le fichier ExportOptions.plist pour App Store
cat > /tmp/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

echo -e "${BLUE}📤 Exporting for App Store...${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist /tmp/ExportOptions.plist

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Export failed${NC}"
    echo -e "${BLUE}ℹ️  Note: Vous devrez peut-être configurer votre Team ID dans ExportOptions.plist${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ App Store build completed successfully!${NC}"
echo ""
echo -e "${BLUE}📍 Files are located at:${NC}"
echo "  - Archive: $ARCHIVE_PATH"
echo "  - App: $EXPORT_PATH/$PROJECT_NAME.app"
echo ""
echo -e "${BLUE}📤 Next steps:${NC}"
echo "  1. Open Xcode Organizer (Window > Organizer)"
echo "  2. Select the archive"
echo "  3. Click 'Distribute App'"
echo "  4. Choose 'App Store Connect'"
echo "  5. Follow the wizard to upload"
echo ""
echo -e "${BLUE}🔗 Or use Transporter:${NC}"
echo "  1. Open Transporter app"
echo "  2. Drag & drop the .app file"
echo "  3. Click 'Deliver'"
echo ""
