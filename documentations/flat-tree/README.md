# Guide d'utilisation de flat-tree.js

## Description

`flat-tree.js` est un utilitaire en ligne de commande qui génère une liste à plat de tous les fichiers et dossiers d'un répertoire, avec leur chemin relatif (commençant par `./`). Il respecte les exclusions définies dans le fichier `.gitignore` et permet d'ajouter des exclusions supplémentaires.

## Installation

### Prérequis

- Node.js version 12.0.0 ou supérieure

### Installation des dépendances

```bash
npm install commander
```

### Installation du script

1. Sauvegardez le script dans un fichier nommé `flat-tree.js`
2. Rendez-le exécutable (Linux/macOS uniquement) :
   ```bash
   chmod +x flat-tree.js
   ```

## Utilisation

### Commande de base

```bash
node flat-tree.js
```

Cette commande listera tous les fichiers et dossiers du répertoire courant, en respectant les exclusions du fichier `.gitignore`.

### Options disponibles

- `-e, --exclude <pattern>` : Dossiers supplémentaires à exclure (séparés par des pipes `|`)
- `-o, --output <file>` : Sauvegarde la sortie dans un fichier
- `-c, --copy` : Copie la sortie dans le presse-papiers
- `-d, --debug` : Active le mode debug (affiche des informations détaillées sur les exclusions)
- `-h, --help` : Affiche l'aide
- `-V, --version` : Affiche la version

## Exemples d'utilisation

### Utilisation standard

```bash
node flat-tree.js
```

Exemple de sortie :
```
.
./README.md
./package.json
./src
./src/index.js
./src/utils
./src/utils/helper.js
```

### Exclure des dossiers supplémentaires

```bash
node flat-tree.js --exclude "logs|temp|cache"
```

### Sauvegarder la sortie dans un fichier

```bash
node flat-tree.js --output structure.txt
```

### Copier la sortie dans le presse-papiers

```bash
node flat-tree.js --copy
```

### Combiner plusieurs options

```bash
node flat-tree.js -e "logs|temp" -o structure.txt -c
```

### Mode debug

```bash
node flat-tree.js --debug
```

## Comportement par défaut

- Le script respecte automatiquement les exclusions définies dans le fichier `.gitignore`
- Par défaut, les répertoires `project-structure` et `.git` sont toujours exclus
- Le format de sortie commence par `.` pour le répertoire racine et préfixe tous les autres chemins avec `./`
- Les chemins utilisent des barres obliques (`/`) même sous Windows pour une sortie cohérente

## Traitement des patterns d'exclusion

Le script prend en charge les types de patterns d'exclusion suivants :

1. **Noms simples** : `node_modules`, `dist`, `.DS_Store`
2. **Patterns avec astérisque** : `*.log`, `temp*`, `*.min.js`
3. **Chemins relatifs** : `build/logs`, `src/tests`

## Notes de compatibilité

- Fonctionne sur Windows, macOS et Linux
- Utilise la bibliothèque `commander` pour l'analyse des arguments de ligne de commande
- Le script détecte automatiquement la plate-forme et utilise les méthodes appropriées pour les opérations spécifiques (comme la copie dans le presse-papiers)