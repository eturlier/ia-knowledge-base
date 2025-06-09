# IA Knowledge Base : Base de connaissance partagée pour GPT personnalisé

Permet de charger les fichiers de la base de connaissances dans des GPT personnalisés.

## Présentation

Ce projet regroupe tout ce qu'il faut pour créer un GPT personnalisé avec chargement d'une base de connaissance pour un projet github.
TODO => A faire pour Gitlab

Contenu :

- **Instructions pour un GPT personnalisé** (./agents/ia-po-instructions.md et ./agents/ia-tech-lead-instructions.md)
- **Script permettant de mettre à jour votre base de connaissance** (./documentations/kb.sh)
- Intégration avec **GitHub Actions** pour automatiser la génération.

## Fonctionnement général

1. Copier le dossier `./documentations` à la racine de votre projet.
2. Remplir le fichier `./documentations/kb.txt` avec les chemins des fichiers à intégrer dans la base de connaissance.
3. Utiliser le script `kb.sh` pour générer le fichier `kb.md`.
4. Option : automatiser cette génération via GitHub Actions.

## Mise à jour automatique de la base de connaissance

### Objectif  

Générer et mettre à jour automatiquement la base de connaissance (`kb.md`) grâce au script `kb.sh` et à une action GitHub.

### Étapes d'utilisation

### 1. Cloner le projet

```bash
git clone https://github.com/eturlier/ia-knowledge-base.git
cd ia-knowledge-base
```

### 2. Configurer les fichiers à inclure dans la base de connaissance

Ouvre et modifie le fichier :  

```bash
/documentations/kb.txt
```

Exemple de contenu :

```text
package.json
apps/frontend/package.json
apps/backend/package.json
apps/backend/swagger.json
```

### 3. Générer la base de connaissance manuellement

```bash
cd documentations
./kb.sh
```

Le fichier `kb.md` sera mis à jour dans le dossier `documentations/`.

### 4. Mise à jour automatique via GitHub Actions

L’action GitHub est déjà configurée dans :

```bash
.github/workflows/update-kb.yml
```

Elle se déclenche automatiquement :

- Lors d’un **push** dans le dossier `documentations/**`.
- Ou **manuellement** via l’interface GitHub.

### 5. Lancer manuellement depuis GitHub

1. Ouvre l’onglet **Actions** de ton repo GitHub.
2. Sélectionne le workflow **"Update Knowledge Base"**.
3. Clique sur **"Run workflow"**.

### ✅ Résultat attendu

- Le fichier `documentations/kb.md` est mis à jour avec les derniers fichiers listés dans `kb.txt`.
- Si aucun changement, aucun commit n’est effectué.

## Guide : connecter votre GPT personnalisé à la base de connaissance

Ce projet vous permet de **créer un GPT personnalisé** qui utilise automatiquement votre base de connaissance (`kb.md`) générée depuis votre projet.

---

### Étape 1 : Créer votre GPT personnalisé

1. Rendez-vous sur :  
   👉 [https://chatgpt.com/gpts/editor](https://chatgpt.com/gpts/editor)

2. Cliquez sur **"Create a GPT"**.

3. Configurez votre GPT :  
   - Donnez-lui un nom.  
   - Définissez son **personality / system prompt** avec un des fichiers d'instructions disponible dans le dossier `agents/`.  
   - Passez à l’étape **"Actions"** (voir ci-dessous).

### Étape 2 : Ajouter l’action pour charger la base de connaissance

OpenAI GPT personnalisés permettent d’utiliser des **actions** (basées sur une spécification OpenAPI).

Avec ce projet, l’action est déjà définie dans le fichier :  

```text
/agents/action-gpt.yml
```

Cette action permet de charger le fichier `kb.md` directement depuis GitHub.

Du coup tu peut copier directement son contenu dans les actions de ton GPT.

### Étape 3 : Configuration de votre Custom GPT avec le token GitHub

1. Accéder à la plateforme GPT Builder
   - Connectez-vous à votre compte OpenAI
   - Accédez à la section GPT Builder ou Custom GPT
2. Créer ou modifier votre Custom GPT
   - Si vous créez un nouveau GPT, cliquez sur "Create a GPT"
   - Si vous modifiez un GPT existant, sélectionnez-le dans votre liste
3. Configurer les actions (Actions)
   - Dans l'interface de création/modification, allez à la section "Actions" ou "Capacités"
   - Activez l'option "Actions" si ce n'est pas déjà fait
4. Importer votre fichier OpenAPI
   - Cliquez sur "Import from OpenAPI" ou "Importer depuis OpenAPI"
Vous pouvez soit :
   - Télécharger votre fichier action-gpt.yml
   - Copier-coller le contenu du fichier
   - Fournir l'URL du fichier (s'il est accessible publiquement)
5. Configurer l'authentification
   - Une fois le fichier importé, vous devriez voir une option pour configurer l'authentification
   - Sélectionnez "Bearer" comme type d'authentification
   - Dans le champ du token, entrez votre token d'accès personnel GitHub (sans le préfixe "Bearer")
   - Si le système vous demande d'ajouter le préfixe "Bearer", suivez les instructions
6. Tester la connexion
   - Utilisez l'option "Test" pour vérifier que l'authentification fonctionne correctement
   - Assurez-vous que le Custom GPT peut accéder au fichier spécifié dans votre dépôt

### Étape 4 : Comprendre le fonctionnement

- **Quand l’utilisateur démarre une session avec votre GPT personnalisé :**
  - Le GPT exécute automatiquement l’action `fetchKnowledgeBase`.
  - Il récupère le fichier `kb.md` avec la dernière mise à jour.
  - Il utilise ce contenu comme **contexte** pour répondre aux questions.

⚠️ **Important :**  
> Le fichier `kb.md` est lu brut par le GPT (pas d’embeddings, pas de découpe automatique).  
> Si le fichier est trop gros, il risque d’être tronqué ou ignoré.

### Schéma du fonctionnement global

```text
Développeur
    ↳ Met à jour les fichiers projet
        ↳ GitHub Action génère kb.md
GPT Personnalisé (via OpenAI)
    ↳ Appelle fetchKnowledgeBase → récupère kb.md
        ↳ Utilise le contenu comme contexte pour répondre à l’utilisateur
```

---

### 🟢 Résultat

Votre GPT est capable de répondre aux questions sur le projet avec les dernières informations issues de votre dépôt GitHub, sans avoir besoin de réécrire les specs manuellement.
