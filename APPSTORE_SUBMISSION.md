# Guide de soumission App Store - PastScreen

## 📋 Préparation complète effectuée

### ✅ Fichiers créés
1. **Info-AppStore.plist** - Info.plist sans clés Sparkle
2. **PastScreenAppStore.entitlements** - Entitlements avec sandbox activé
3. **scripts/build_appstore.sh** - Script de build automatisé
4. **PastScreenApp.swift** - Code avec compilation conditionnelle (#if !APPSTORE)

### ✅ Modifications du code
- `import Sparkle` → Conditionnel avec `#if !APPSTORE`
- `updaterController` → Conditionnel
- Menu "Check for Updates" → Conditionnel
- Initialisation Sparkle → Conditionnelle

---

## 🎯 Étapes de soumission

### 1. Configuration Xcode

#### A. Créer une cible App Store (manuel dans Xcode)

1. Ouvre `PastScreen.xcodeproj` dans Xcode
2. Sélectionne le projet "PastScreen" dans le navigateur
3. Sélectionne la cible "PastScreen"
4. Clic droit → **"Duplicate"**
5. Renomme "PastScreen copy" → **"PastScreen AppStore"**

#### B. Configurer la cible App Store

Dans **Build Settings** de "PastScreen AppStore":

```
Product Name: PastScreen
Product Bundle Identifier: com.ecologni.PastScreen
Code Signing Identity: Apple Distribution
Code Signing Entitlements: PastScreenAppStore.entitlements
Info.plist File: PastScreen/Info-AppStore.plist
```

Dans **Other Swift Flags**, ajoute:
```
-D APPSTORE
```

#### C. Retirer Sparkle de la cible App Store

1. Sélectionne cible **"PastScreen AppStore"**
2. **Build Phases** → **Link Binary With Libraries**
3. Trouve `Sparkle.framework` → Clique **"-"** pour retirer
4. **Build Phases** → **Embed Frameworks**
5. Pareil, retire `Sparkle.framework`

---

### 2. App Store Connect - Préparation

#### A. Créer l'app dans App Store Connect

1. Va sur [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **"+"** → **New App**
3. Remplis:
   - **Platform**: macOS
   - **Name**: PastScreen
   - **Primary Language**: Français (ou Anglais)
   - **Bundle ID**: com.ecologni.PastScreen
   - **SKU**: pastscreen-macos (unique ID interne)

#### B. Métadonnées requises

**Screenshots** (déjà dans `onboarding/`):
- Minimum 1 screenshot, recommandé 3-5
- Taille recommandée: 1280×800 ou 2880×1800 (Retina)
- Utilise les screenshots d'onboarding déjà préparés

**Description** (exemple):
```
PastScreen - Capture d'écran ultra-rapide pour développeurs

PastScreen est un outil de productivité conçu pour les développeurs qui
ont besoin de captures d'écran instantanées copiées directement au
presse-papiers.

Fonctionnalités:
• Raccourci clavier global personnalisable (défaut: ⌥⌘S)
• Copie automatique au presse-papiers
• Support multi-écrans
• Intégration Siri/Shortcuts
• Interface minimaliste (menu bar uniquement)
• Sauvegarde optionnelle sur disque

Parfait pour:
- Coller rapidement dans VSCode, Cursor, Xcode
- Documentation technique
- Partage rapide sur Slack, Discord
- Screenshots pour GitHub Issues

Permissions requises:
- Screen Recording: Pour capturer l'écran
- Accessibility: Pour le raccourci clavier global
- Notifications: Pour confirmer les captures
```

**Keywords** (100 caractères max):
```
screenshot,capture,clipboard,developer,productivity,hotkey,menubar
```

**Support URL**: https://github.com/augiefra/PastScreen

**Privacy Policy URL**: (À créer si nécessaire)

#### C. Justification Screen Recording (CRUCIAL)

Dans la section **"App Review Information"**, ajoute une note pour l'équipe de review:

```
PastScreen requires Screen Recording permission for the following reasons:

1. Core Functionality: The app's primary purpose is to capture user-selected
   screen regions and copy them directly to the clipboard. This is not possible
   with native macOS screenshot APIs (Cmd+Shift+4) as they don't provide
   programmatic clipboard access.

2. Developer Productivity: Our target users (software developers) need instant
   clipboard integration to paste screenshots into IDEs (VSCode, Cursor, Xcode)
   without manual file selection.

3. App Intents/Shortcuts: Screen Recording is required for our Shortcuts
   integration, allowing users to automate screenshot workflows.

4. Multi-Screen Support: Our custom overlay selection UI requires ScreenCaptureKit
   to properly handle multi-monitor setups with accurate color profiles and
   resolution.

The permission is requested via our onboarding flow with clear explanations
of why each permission is needed.
```

---

### 3. Build et Archive

#### Option A: Utiliser le script automatique

```bash
cd /Users/ecologni/Desktop/Clemadel/PastScreen
./scripts/build_appstore.sh
```

**⚠️ Note**: Tu devras modifier le script pour ajouter ton Team ID dans `ExportOptions.plist`

#### Option B: Manuellement dans Xcode

1. Ouvre Xcode
2. Sélectionne la cible **"PastScreen AppStore"**
3. Menu **Product** → **Archive**
4. Attends la fin du build (~2 minutes)
5. L'Organizer s'ouvre automatiquement

---

### 4. Upload vers App Store Connect

#### Option A: Via Xcode Organizer (recommandé)

1. Dans Organizer, sélectionne l'archive
2. Clique **"Distribute App"**
3. Choisis **"App Store Connect"**
4. **Upload** (pas "Export")
5. Sélectionne:
   - ✅ Upload symbols
   - ✅ Manage Version and Build Number (auto-increment)
6. Choisis le profil de signature (automatique)
7. Clique **"Upload"**
8. Attends (~5-10 minutes)

#### Option B: Via Transporter app

1. Ouvre **Transporter** (installé avec Xcode)
2. Drag & drop le fichier `.pkg` exporté
3. Clique **"Deliver"**
4. Attends la validation

---

### 5. Soumission pour review

1. Retourne sur [App Store Connect](https://appstoreconnect.apple.com)
2. Sélectionne PastScreen
3. Va dans **"App Store"** → **"macOS App"**
4. Clique **"+ Version"** (si nouveau)
5. Remplis **"What's New in This Version"**
6. Dans **"Build"**, sélectionne le build uploadé
7. Remplis toutes les métadonnées requises:
   - Screenshots
   - Description
   - Keywords
   - Support URL
   - Privacy URL (si applicable)
   - Category: **Developer Tools**
   - Content Rights: Sélectionne approprié
8. **App Review Information**:
   - Ajoute la justification Screen Recording
   - Fournis des credentials de test si nécessaire
9. Clique **"Submit for Review"**

---

## ⚠️ Points d'attention critiques

### 1. Screen Recording Permission

Apple est TRÈS strict sur cette permission. Ta justification doit être:
- **Spécifique**: Explique pourquoi les APIs natives ne suffisent pas
- **Nécessaire**: Montre que c'est la fonctionnalité CORE de l'app
- **Transparente**: L'onboarding explique clairement pourquoi

**Risque de rejet**: Élevé si justification insuffisante

**Solution si rejet**:
- Ajoute des screenshots montrant l'onboarding qui explique les permissions
- Fournis une vidéo démo montrant le workflow complet
- Propose un test account pour la review team

### 2. Sandbox Restrictions

Avec `com.apple.security.app-sandbox = true`:
- ✅ Accès fichiers utilisateur (read/write) - OK
- ✅ Apple Events vers System Events - OK
- ❌ Pas d'accès réseau non justifié
- ❌ Pas d'accès à tous les fichiers

**Vérifie** que l'app fonctionne correctement en mode sandbox:
```bash
# Test en sandbox
codesign -d --entitlements :- /path/to/PastScreen.app
```

### 3. Privacy Manifest (macOS 14+)

Si tu cibles macOS 14+, Apple peut demander un **Privacy Manifest** (`PrivacyInfo.xcprivacy`).

**À créer si demandé**:
1. Xcode → File → New File → **App Privacy**
2. Déclare:
   - Screen Recording usage
   - Accessibility usage
   - Notifications usage

### 4. Sparkle complètement retiré

**Vérifie** avant upload:
```bash
# Chercher toute référence à Sparkle dans le build
strings /path/to/PastScreen.app/Contents/MacOS/PastScreen | grep -i sparkle
```

Si tu vois des résultats → Le flag `APPSTORE` n'a pas fonctionné

---

## 📊 Timeline attendu

| Étape | Durée |
|-------|-------|
| Upload vers App Store Connect | 5-10 min |
| Processing by Apple | 30-60 min |
| "Waiting for Review" | 1-3 jours |
| "In Review" | 1-2 jours |
| Approved / Rejected | Notification immédiate |

**Total moyen**: 3-5 jours pour première soumission

---

## 🔄 Processus de mise à jour

Pour les futures versions:

1. Incrémente `CFBundleShortVersionString` (ex: 1.6.1 → 1.7.0)
2. Incrémente `CFBundleVersion` (ex: 10 → 11)
3. Archive avec cible App Store
4. Upload
5. Dans App Store Connect → **"+ Version"**
6. Remplis "What's New"
7. Submit for review

**⚠️ Note**: Maintiens DEUX versions:
- **Version normale** (com.augiefra.PastScreen) → Distribution directe avec Sparkle
- **Version App Store** (com.ecologni.PastScreen) → App Store sans Sparkle

---

## 🛠️ Troubleshooting

### Problème: "Invalid Bundle - Missing Info.plist keys"
**Solution**: Vérifie que `Info-AppStore.plist` est bien utilisé par la cible App Store

### Problème: "Invalid Entitlement"
**Solution**: Vérifie `PastScreenAppStore.entitlements`, compare avec [Apple Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)

### Problème: "Sparkle Framework Found"
**Solution**: Vérifie Build Phases → Link Binary, retire Sparkle manuellement

### Problème: "Code Signing Error"
**Solution**:
1. Xcode → Preferences → Accounts → Download Manual Profiles
2. Build Settings → Code Signing Identity → Apple Distribution

---

## 📞 Support

Si problème:
1. [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
2. [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
3. [Apple Developer Forums](https://developer.apple.com/forums/)

---

**Dernière mise à jour**: 2025-11-18
