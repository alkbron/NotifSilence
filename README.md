# NotifSilence 🔕

Un mode silencieux pour Mac, comme le bouton silencieux de l'iPhone : **les notifications continuent de s'afficher, mais sans son**, et ta musique, tes vidéos et tes appels gardent leur volume normal.

Une petite icône dans la barre des menus, un clic pour basculer :

| Icône | État |
|-------|------|
| 🔔 `bell` | Notifications sonores (comportement normal) |
| 🔕 `bell.slash.fill` | Notifications silencieuses |

## Pourquoi

Sur macOS, la barre de volume règle à la fois le son du Mac et celui des notifications. Les solutions existantes ne conviennent pas :

- **couper le son** coupe aussi la musique et les vidéos ;
- **Ne pas déranger / Concentration** masque les notifications : tu ne les vois plus.

## Comment ça marche

macOS a un second réglage, souvent oublié : **Réglages Système → Son → Volume des alertes**. C'est un pourcentage du volume système, appliqué uniquement aux sons de notifications et aux bips système :

```
son d'une notification ≈ volume système × volume des alertes
```

NotifSilence passe simplement ce volume des alertes à **0 %** en mode silencieux, puis remet ta valeur précédente quand tu le désactives. Le volume système n'est jamais modifié. Pas d'API privée, pas de permission spéciale.

## Limites

- Seuls les sons joués **par macOS** sont coupés : les notifications natives (Messages, Mail, Calendrier, la plupart des apps).
- Les apps qui jouent **leur propre son** en interne (certaines apps Electron : Discord, Teams, WhatsApp…) ne sont pas concernées. Coupe leur son dans leurs propres réglages.
- On ne peut pas rendre les notifications plus fortes que le volume système.

## Installation

Prérequis : macOS 13+ et **Xcode 26+** (pour compiler l'icône au format Icon Composer). Avec les seuls outils en ligne de commande (`xcode-select --install`), l'app se construit aussi, mais macOS 26+ affichera son icône dans un carré gris.

```sh
git clone https://github.com/alkbron/NotifSilence.git
cd NotifSilence
./build.sh install
```

Ça compile l'app, la copie dans `/Applications` et la lance. Pour juste compiler (dans `build/NotifSilence.app`) :

```sh
./build.sh
```

## Utilisation

- **Clic gauche** : active / désactive le mode silencieux.
- **Clic droit** (ou ⌃ clic) : menu avec « Mode silencieux », « Ouvrir au démarrage » et « Quitter ».
- **⌘ + glisser** l'icône pour la placer où tu veux dans la barre des menus.

> L'icône n'apparaît pas ? Sur les MacBook à encoche, macOS cache les icônes qui ne rentrent pas dans la barre. Quitte une autre app de la barre des menus pour lui faire de la place.

## Structure

```
Sources/NotifSilence/
├── AlertVolume.swift   # lecture / écriture du volume des alertes (AppleScript)
└── main.swift          # icône, clics, menu, ouverture au démarrage
Resources/
├── AppIcon.icon/       # icône au format Icon Composer (macOS 26+)
└── AppIcon.png         # icône 1024 px de repli (.icns classique)
build.sh                # construit le bundle .app (signature ad hoc)
```

## Licence

[MIT](LICENSE)
