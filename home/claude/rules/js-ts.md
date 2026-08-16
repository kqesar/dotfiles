# Écosystème JS / TypeScript

## Gestionnaire de paquets : pnpm, sans exception
- **pnpm quoi qu'il arrive**, front comme back : jamais npm, yarn ou bun, même pour une commande ponctuelle ou un projet jetable.
- Conséquences à respecter partout :
  - Commandes : `pnpm install`, `pnpm add`, `pnpm dlx` (à la place de `npx`), `pnpm <script>`.
  - Lockfile : `pnpm-lock.yaml` uniquement. S'il existe un `package-lock.json` ou un `yarn.lock` dans un repo, le signaler et proposer la migration.
  - Docker & CI/CD : activer pnpm via Corepack, installer avec `--frozen-lockfile`, et tirer parti du store pnpm en cache entre les builds.
  - Monorepo : `pnpm-workspace.yaml` (pas de workspaces npm/yarn).
- Si un outil ou un script généré suppose npm/yarn, l'adapter à pnpm au lieu de l'accepter tel quel.

### Épingler pnpm : Corepack + champ `packageManager`
Le lockfile fige les dépendances, pas le gestionnaire qui les installe. Sans épinglage, deux machines résolvent le même `pnpm-lock.yaml` avec deux versions de pnpm — c'est une source de builds divergents entre poste local et CI.

- **Scaffolding d'un nouveau projet** : `pnpm init`, puis **toujours** `corepack use pnpm@latest`. Le second écrit un champ `packageManager` en version exacte + hash d'intégrité (`pnpm@X.Y.Z+sha512...`), ce que `pnpm init` seul ne fait pas.
- Le champ `packageManager` doit **toujours** porter une version exacte. Jamais un range : Corepack les refuse (`Invalid package manager specification…; expected a semver version`).
- Piège connu : `pnpm init` (pnpm 11) écrit un range dans `devEngines.packageManager`, incompatible avec Corepack. Le `packageManager` posé par `corepack use` fait foi côté Corepack ; supprimer le bloc `devEngines` pour éviter l'avertissement de pnpm sur les deux versions divergentes.
- **CI & Docker** : `corepack enable` suffit — la version de pnpm vient du repo. Ne jamais faire `npm i -g pnpm`, qui réintroduit une version flottante et contourne l'épinglage.
- **Poste local** : les shims Corepack vivent dans le `bin/` de la version de Node active. Relancer `corepack enable` après chaque installation d'une nouvelle version de Node (nvm, fnm…).

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
