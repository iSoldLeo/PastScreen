# 📸 ScreenSnap

**Captures d'écran ultra-rapides pour développeurs**

Application macOS avec workflow optimisé : Capturez → ⌘V → Collé dans votre IDE !

[![Version](https://img.shields.io/badge/version-1.1-blue.svg)](https://github.com/augiefra/ScreenSnap/releases/tag/v1.1)
[![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## ✨ Nouveautés v1.1

- 🎨 **Onboarding Moderne** : Interface liquid glass avec 4 pages animées
- 🌍 **Multilingue** : Support complet FR/EN/ES/DE/IT
- 🖼️ **Toggle Dock** : Choisissez d'afficher ou non l'icône dans le Dock
- 📐 **Préférences Améliorées** : Interface agrandie et optimisée
- 🧹 **Nettoyage** : Suppression des options non fonctionnelles

## 🚀 Fonctionnalités

- 📸 **Capture de zone** : Sélection interactive avec overlay translucide
- 🖥️ **Capture plein écran** : Un clic pour tout capturer
- ⚡ **Ultra-rapide** : ⌘⇧5 → Capturer → ⌘V → Collé !
- 📋 **Copie automatique** : Direct dans le clipboard pour vos IDEs
- 🧹 **Nettoyage auto** : Fichiers temporaires vidés au redémarrage
- 🔔 **Notifications** : Cliquez pour ouvrir dans Finder
- 🎨 **Interface moderne** : Onboarding liquid glass style Apple
- 🌍 **Multilingue** : Français, English, Español, Deutsch, Italiano
- ⚙️ **Personnalisable** : Format, son, raccourcis, stockage, Dock

## 💾 Installation

### Depuis DMG (Recommandé)

1. **Télécharger** : [ScreenSnap-1.1.dmg](https://github.com/augiefra/ScreenSnap/releases/latest)
2. **Monter** le DMG
3. **Glisser** `ScreenSnap.app` vers `Applications`
4. **Lancer** depuis Applications
5. **Autoriser** les permissions (Enregistrement d'écran + Accessibilité)

### Depuis Sources

```bash
git clone https://github.com/augiefra/ScreenSnap
cd ScreenSnap
open ScreenSnap.xcodeproj
```

Puis : `Product → Archive → Export`

## 🎯 Utilisation

### Raccourcis Clavier

- **⌘⇧5** : Capturer une zone (raccourci par défaut)
- **Clic icône menu bar** : Ouvrir le menu complet

### Menu Bar

- 📸 Capturer une zone ⌘⇧5
- 🖥️ Capturer l'écran complet
- 📁 Afficher la dernière capture
- ⚙️ Préférences...
- ❌ Quitter ScreenSnap

### Workflow Développeur

```
1. ⌘⇧5 (ou clic menu bar)
2. Sélectionner la zone à capturer
3. ⌘V dans Cursor/VSCode/Zed
   → Image collée directement !
```

**Parfait pour :**
- Coller des screenshots dans Claude Code, Cursor, Zed, VSCode
- Partager des bugs sur Slack, Discord, Linear, GitHub Issues
- Documenter dans Figma, Notion, Obsidian

## ⚙️ Configuration

### Onglet Général
- ✅ Afficher l'icône dans le Dock
- ✅ Copier dans le presse-papiers (auto)
- 🔊 Jouer un son lors de la capture
- 📋 Afficher le tutoriel de démarrage

### Onglet Capture
- 🖼️ **Format** : PNG (sans perte) ou JPEG (compressé)
- ⌨️ **Raccourci** : Configurable (défaut ⌘⇧5)
- 🎹 Activer le raccourci global

### Onglet Stockage
- 💾 **Enregistrer sur le disque** : Optionnel
- 📁 **Dossier** : Temp (auto-nettoyé) ou permanent
- 🗑️ **Vider le dossier** : Nettoyage manuel

## 🌍 Langues Supportées

ScreenSnap détecte automatiquement la langue système :

- 🇫🇷 **Français** - Interface complète + onboarding
- 🇬🇧 **English** - Full interface + onboarding
- 🇪🇸 **Español** - Interfaz completa + onboarding
- 🇩🇪 **Deutsch** - Vollständige Oberfläche + Onboarding
- 🇮🇹 **Italiano** - Interfaccia completa + onboarding

## 🛠️ Développement

### Prérequis
- macOS 13.0+ (Ventura)
- Xcode 15+
- Swift 5.9+

### Structure du Projet

```
ScreenSnap/
├── ScreenSnap/
│   ├── ScreenSnapApp.swift           # Point d'entrée AppKit
│   ├── Models/
│   │   └── AppSettings.swift         # Singleton settings
│   ├── Views/
│   │   ├── SettingsView.swift        # SwiftUI preferences
│   │   ├── ModernOnboardingView.swift     # Liquid glass onboarding
│   │   └── ModernOnboardingWindow.swift   # Window manager
│   ├── Services/
│   │   ├── ScreenshotService.swift   # Core capture logic
│   │   └── HotKeyManager.swift       # Global hotkeys
│   ├── Utils/
│   │   └── Logger.swift              # Debug logging
│   └── *.lproj/                      # Localizations
│       └── Localizable.strings
└── SelectionWindow.swift             # Capture overlay
```

### Technologies

- **SwiftUI** : Interface moderne (onboarding, préférences)
- **AppKit** : Menu bar, fenêtres, sélection overlay
- **Carbon API** : Raccourcis clavier globaux
- **CGDisplayImage** : Capture d'écran native
- **NSPasteboard** : Gestion clipboard
- **UserDefaults** : Persistance settings

### Build

```bash
# Debug
xcodebuild -scheme ScreenSnap -configuration Debug build

# Release
xcodebuild -scheme ScreenSnap -configuration Release build
```

### Créer le DMG

```bash
# Installer create-dmg
brew install create-dmg

# Build Release
xcodebuild -scheme ScreenSnap -configuration Release build

# Copier l'app
cp -R ~/Library/Developer/Xcode/DerivedData/.../ScreenSnap.app ~/Desktop/

# Créer le DMG
create-dmg \
  --volname "ScreenSnap" \
  --background "dmg-background.png" \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 425 190 \
  "ScreenSnap-1.1.dmg" \
  "~/Desktop/ScreenSnap.app"
```

## 📝 Permissions Requises

### Enregistrement d'écran
**Pourquoi ?** Pour capturer le contenu de l'écran

**Comment ?** Système → Confidentialité → Enregistrement d'écran → ✅ ScreenSnap

### Accessibilité
**Pourquoi ?** Pour le raccourci clavier global ⌘⇧5

**Comment ?** Système → Confidentialité → Accessibilité → ✅ ScreenSnap

⚠️ **Ces permissions sont demandées automatiquement au premier lancement**

## ✨ Pourquoi ScreenSnap ?

### vs. Capture macOS Native
| Native | ScreenSnap |
|--------|------------|
| ❌ Fichiers s'accumulent sur le Bureau | ✅ Nettoyage automatique au redémarrage |
| ❌ Pas de raccourci personnalisé | ✅ Raccourcis configurables |
| ❌ Interface basique | ✅ Onboarding moderne liquid glass |

### vs. Autres Apps de Screenshot
| Autres Apps | ScreenSnap |
|-------------|------------|
| ❌ Interface complexe | ✅ Simple et rapide |
| ❌ Pas de nettoyage auto | ✅ Workflow "jetable" optimisé |
| ❌ Mono-langue | ✅ Multilingue (5 langues) |
| ❌ Dock encombré | ✅ Mode menu bar uniquement |

### Workflow Optimisé Développeurs

```
Problème : Capturer un bug → Trouver le fichier → L'envoyer
Solution : ⌘⇧5 → ⌘V → Déjà collé dans Slack !

Problème : Screenshots partout sur le Bureau
Solution : Auto-cleanup au redémarrage → Bureau toujours propre

Problème : Interface complexe avec 20 options
Solution : 3 clics max pour configurer, workflow immédiat
```

## 🤝 Contribution

Les contributions sont bienvenues !

1. **Fork** le projet
2. **Créer** une branche (`git checkout -b feature/amelioration`)
3. **Commit** (`git commit -m 'feat: Ajout fonctionnalité'`)
4. **Push** (`git push origin feature/amelioration`)
5. **Ouvrir** une Pull Request

### Guidelines

- Code Swift propre (SwiftLint)
- Tests pour nouvelles fonctionnalités
- Documentation en français ET anglais
- Commit messages conventionnels (feat/fix/docs/refactor)

## 📄 Licence

MIT License - Voir [LICENSE](LICENSE)

## 🔗 Liens Utiles

- **Documentation** : [CLAUDE.md](CLAUDE.md)
- **Releases** : [GitHub Releases](https://github.com/augiefra/ScreenSnap/releases)
- **Issues** : [GitHub Issues](https://github.com/augiefra/ScreenSnap/issues)
- **Changelog** : Voir releases pour historique complet

## 🎉 Changelog v1.1

### Ajouté
- ✨ Onboarding moderne avec liquid glass effect et 4 pages animées
- 🌍 Support multilingue complet (FR/EN/ES/DE/IT)
- 🖼️ Toggle pour afficher/masquer l'icône Dock
- 📐 Fenêtre de préférences agrandie (600x500)

### Amélioré
- 🧹 Nettoyage des préférences (suppression options non fonctionnelles)
- 🎨 Interface onboarding avec animations spring
- 📝 Traductions natives pour toutes les langues

### Technique
- SwiftUI animations fluides
- NSLocalizedString pour i18n
- VisualEffectBlur pour liquid glass
- Backward compatibility via typealias

---

**Version** : 1.1
**Build** : 3
**Compatibilité** : macOS 13.0+ (Ventura, Sonoma, Sequoia)
**Auteur** : Eric COLOGNI
**License** : MIT
