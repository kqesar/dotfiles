---
paths:
  - "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs,vue,svelte}"
  - "**/package.json"
  - "**/pnpm-{lock,workspace}.yaml"
  - "**/tsconfig*.json"
  - "**/{vite,vitest,playwright}.config.*"
  - "**/Dockerfile*"
  - "**/.github/workflows/*.{yml,yaml}"
---

# Écosystème JS / TypeScript

## Gestionnaire de paquets : pnpm, sans exception
- **pnpm quoi qu'il arrive**, front comme back : jamais npm, yarn ou bun, même pour une commande ponctuelle ou un projet jetable.
- Conséquences à respecter partout :
  - Commandes : `pnpm install`, `pnpm add`, `pnpm dlx` (à la place de `npx`), `pnpm <script>`.
  - Lockfile : `pnpm-lock.yaml` uniquement. S'il existe un `package-lock.json` ou un `yarn.lock` dans un repo, le signaler et proposer la migration.
  - Docker & CI/CD : pnpm fourni par son propre installeur (voir ci-dessous), installation avec `--frozen-lockfile`, store pnpm en cache entre les builds.
  - Monorepo : `pnpm-workspace.yaml` (pas de workspaces npm/yarn).
- Si un outil ou un script généré suppose npm/yarn, l'adapter à pnpm au lieu de l'accepter tel quel.

### Épingler pnpm : `package.json` + lockfile, sans Corepack
Le lockfile fige les dépendances, pas le gestionnaire qui les installe. Sans épinglage, deux machines résolvent le même `pnpm-lock.yaml` avec deux versions de pnpm — source de builds divergents entre poste local et CI.

**Corepack n'est plus une option.** Node ne le livre plus depuis la 25.0.0 (changelog v25 : « build: stop distributing Corepack », SEMVER-MAJOR). Constaté le 2026-10-18 : le `bin/` de Node 26.12 ne contient que `node`, `npm`, `npx`, et la page de doc Corepack de la v26 renvoie 404. pnpm s'installe donc hors de Node.

- **Poste local** : pnpm autonome, `curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION=<version exacte> sh -`. Il s'installe dans `~/.local/share/pnpm` (mettre `$PNPM_HOME/bin` dans le PATH) et ne dépend d'aucune version de Node : rien à refaire après une montée de Node. Version par défaut : **pnpm 12** (le portage en Rust, selon le script d'installation). Lire le script avant de l'exécuter : pour pnpm ≥ 12 il vérifie la signature du registre npm et refuse d'installer si elle ne correspond pas ; il télécharge la 11.x depuis GitHub Releases sans contrôle d'empreinte.
- **Scaffolding** : garder ce que `pnpm init` écrit. Sur pnpm 12, c'est `packageManager` **et** `devEngines.packageManager` avec la même version exacte (la dernière publiée, pas celle qui tourne) et `onFail: "download"` ; sur pnpm 11, seulement `devEngines.packageManager` en range.
- **L'intégrité vit dans le lockfile, et c'est pnpm 12 qui l'y met.** Le premier `pnpm install` inscrit la version exacte de pnpm **et ses hash sha512** dans `pnpm-lock.yaml` (`packageManagerDependencies`), comme pour n'importe quelle dépendance. Constaté le 2026-10-18 : pnpm 12.14.0 le fait à partir de `packageManager` seul comme de `devEngines.packageManager` ; pnpm 11.22.0 ne le fait qu'avec `devEngines`, jamais avec `packageManager` seul. (Une version antérieure de cette règle attribuait l'effet à `devEngines` ; corrigé après vérification croisée avec une autre session.)
- **Projet existant avec seulement `packageManager`** : pnpm 11 comme 12 bascule de lui-même sur la version fixée (`pmOnFail`, défaut `download` ; constaté : 11.22.0 exécute la 11.21.0 épinglée, 12.14.0 la 12.13.0). Mais le suffixe `+sha512…` n'est **plus vérifié** : un hash faux passe sans erreur, version jamais téléchargée comprise (constaté sur 11.22.0 et 12.14.0) — c'était le travail de Corepack. Migrer : **passer à pnpm 12** (c'est ce qui fait entrer l'intégrité dans le lockfile), retirer le suffixe `+sha512`, puis `pnpm install`. Ajouter `devEngines.packageManager` avec la même version exacte sert à s'aligner sur le format de `pnpm init`, pas à l'intégrité (fait sur un projet le 2026-10-18).
- **CI** : `pnpm/action-setup` lit `packageManager` comme `devEngines.packageManager` ; pas d'input `version` à maintenir. Épingler l'action par SHA (`rules/deployment.md`).
- **Docker** : pnpm installé dans le stage de build par le même script (`wget -qO- https://get.pnpm.io/install.sh | env ENV="$HOME/.shrc" SHELL="$(which sh)" PNPM_VERSION=<version> sh -`, d'après la doc pnpm).
- Ne jamais faire `npm i -g pnpm` : version flottante, épinglage contourné.

## Validation à l'exécution : Zod aux frontières

TypeScript disparaît au build : ses types ne garantissent **rien** sur une donnée qui entre dans le process à l'exécution. Un `as PayloadType` sur un body HTTP est une affirmation non vérifiée, pas une validation. Zod comble ce trou en front comme en back.

### Obligation didactique
Ne jamais introduire Zod comme une dépendance de plus. À chaque fois que la réponse en propose l'usage, **expliquer explicitement** :
- **quelle frontière** est concernée et quelle donnée non fiable la traverse ;
- **ce qui casse sans validation** (le bug concret, pas « c'est plus sûr ») ;
- que **s'en passer est déconseillé**, précisément parce que le projet est en TS : le typage statique donne une illusion de garantie que rien ne vérifie au runtime.

### Où valider
Toute donnée dont l'origine est hors du process :
- corps, paramètres de route et query strings des requêtes HTTP (back) ;
- réponses d'API consommées par le front ou par le back (une API tierce change sans prévenir) ;
- variables d'environnement, au démarrage — l'app doit refuser de booter sur une conf invalide plutôt que planter en production trois heures plus tard ;
- colonnes JSON/JSONB relues depuis la base, contenu de `localStorage`, fichiers uploadés, payloads de webhooks.

### Comment
- **Le schéma est la source de vérité**, le type en dérive : `type User = z.infer<typeof userSchema>`. Jamais l'inverse, jamais les deux maintenus en parallèle.
- Schémas partagés entre front et back dans un package du workspace pnpm quand le monorepo le permet : le contrat ne peut plus désynchroniser.
- `safeParse` aux frontières que l'utilisateur peut atteindre (→ réponse 400 avec erreurs exploitables) ; `parse` là où l'échec est un bug de programmation ou une conf invalide au boot.
- Un message d'erreur de validation ne doit jamais renvoyer la valeur reçue si elle peut contenir un secret ou une donnée personnelle (voir `rules/deployment.md`).

### Où ne pas valider
Valider **une fois**, à l'entrée. Re-parser la même donnée entre deux fonctions internes coûte du CPU sans rien prouver de plus — enjeu réel sur 1 vCore (`rules/infra.md`). Garder les `parse` hors des boucles chaudes et des chemins appelés par requête.

### Alternatives
Zod est le défaut. Si le poids du bundle front devient critique ou si le besoin se limite à des schémas JSON Schema, présenter les alternatives (Valibot, TypeBox, ArkType) avec leur compromis et laisser l'utilisateur trancher (`rules/workflow.md`).

## Mode dev : HMR obligatoire
- Toute app JS/TS, **front comme back**, doit avoir un mode développement avec **hot reloading**. Une boucle de dev qui impose un redémarrage manuel n'est pas acceptable.
  - Front : HMR natif du bundler (Vite en tête), avec préservation de l'état des composants quand le framework le permet.
  - Back : rechargement à chaud du serveur au changement de fichier (watch mode natif du runtime, `tsx watch`, `nodemon`... selon la stack).
- En développement conteneurisé, le HMR doit fonctionner **à travers Docker** : sources montées en volume, port du client HMR exposé, et polling du watcher activé uniquement si l'inotify du host ne remonte pas dans le conteneur (le polling coûte du CPU — voir `rules/infra.md`).
- Le HMR concerne le dev uniquement : il ne doit rien ajouter au build de production.
