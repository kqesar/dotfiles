---
name: frontend-standards
description: Use this skill whenever writing, reviewing, or scaffolding front-end application code — UI components, pages, forms, front-end tooling/config, front-end Dockerfile or nginx conf — in any framework (React, Vue, Angular, Svelte...). Enforces the user's standing conventions for accessibility, responsiveness, TypeScript typing/naming, i18n strategy and key format, testing, API layer (fetch-first), state management, routing, dependency versions, tooling, and build/perf optimization. Trigger on .tsx/.ts/.jsx/.vue files in a front-end project, front-end package.json/vite.config, routing or store setup, or any request to build/modify a web UI.
---

# Front-end standards

## Accessibilité & responsive
- Toute UI doit respecter les normes a11y (rôles ARIA corrects, contrastes suffisants, navigation clavier complète, labels sur les champs de formulaire, focus visible).
- Toujours responsive : smartphone et tablette en plus du desktop (mobile-first ou breakpoints couvrant ces tailles).

## TypeScript
- Les apps front sont toujours en TypeScript.
- Nommage :
  - Types : préfixés par `T` (ex: `TUser`, `TApiResponse`).
  - Interfaces : préfixées par `I` (ex: `IUserProps`, `IUserRepository`).
  - Enums : éviter le mot-clé natif `enum` de TypeScript (il génère du code JS à l'exécution, casse le tree-shaking, et introduit des pièges de comparaison). Préférer un objet `as const` + le type union dérivé (`type TStatus = typeof STATUS[keyof typeof STATUS]`), ou une simple union de littéraux string pour les cas basiques. N'utiliser un enum numérique natif que si le reverse-mapping runtime est réellement requis (interop avec une API/protocole qui l'impose).

## Internationalisation
- Toutes les clés de traduction en snake_case, format `ma_cle_de_trad`.
- Aucune chaîne visible par l'utilisateur en dur dans un composant — messages d'erreur et états vides compris.

### Par défaut : i18n maison
- Tant que le besoin reste simple — deux ou trois langues, des chaînes statiques, pas de pluriel complexe —, **rester sur une solution maison** : un dictionnaire JSON par locale, une fonction `t()` typée, un contexte pour la locale active. Moins de dépendances, bundle plus petit, cohérent avec la cible VPS 2 Go / 1 vCore (`rules/infra.md`).
- **Ne jamais réimplémenter ce que le navigateur fait déjà.** L'API native `Intl` (`NumberFormat`, `DateTimeFormat`, `PluralRules`, `RelativeTimeFormat`, `ListFormat`, `Collator`) gère dates, nombres, devises, pluriels, listes et tri pour toutes les locales, **à coût nul en bundle**. Une i18n maison correcte s'appuie dessus au lieu de coder des règles à la main.
- Typer les clés (`keyof typeof fr`) : une clé manquante ou mal orthographiée doit casser au build, pas en production.

### Signaux de passage à une lib standard
Dès qu'un de ces signaux apparaît, **proposer la migration** avec l'argumentaire (ce que ça simplifie contre le poids de bundle et le coût de migration). L'utilisateur tranche :
- pluriels, genres ou messages imbriqués qui débordent de ce qu'on tient à la main avec `Intl.PluralRules` (→ ICU MessageFormat) ;
- interpolation riche : variables, et surtout balises ou composants dans une traduction (`<0>lien</0>`) ;
- chaîne de fallback entre locales, détection de la locale, traçage des clés manquantes ;
- découpage en namespaces et **chargement paresseux** des paquets de langue par route ;
- **un traducteur non développeur doit intervenir** : un format standard ouvre l'outillage (Weblate, Crowdin, Tolgee, inlang), un format maison le ferme ;
- SSR / pré-rendu, ou routing par locale (`/fr/…`, `/en/…`).

### Options à présenter
- React : `react-i18next` (le plus répandu, écosystème le plus fourni), `LinguiJS`, ou `react-intl`/FormatJS (ICU natif).
- Vue : `vue-i18n`. Svelte : `svelte-i18n`.
- Agnostique et léger : **Paraglide JS** (inlang) — compile les messages, tree-shaking par message, empreinte bundle très basse ; à privilégier quand le poids de page domine l'arbitrage.
- Versions : dernière majeure stable, vérifiée dans le registre npm (`rules/versions.md`).

### Raison structurante
Comme pour le routing : un projet peut finir **public sur GitHub**. Une i18n maison qui a dépassé sa zone de confort devient une barrière à l'entrée pour les contributeurs et une impasse pour les traducteurs, là où une lib standard est immédiatement lisible, documentée et outillée.

### Validation
Les messages d'erreur **Zod** passent par la même couche i18n (error map personnalisée), jamais par des chaînes en dur dans les schémas — voir `rules/js-ts.md`.

## Tests
- Vitest, fichiers `*.spec.ts` / `*.spec.tsx` (jamais `*.test.ts`).
- Les tests couvrent la logique (fonctions pures, hooks, stores, reducers, mappers...), pas le rendu DOM/visuel.

## Appels API
- Client HTTP par défaut : **`fetch` natif**, encapsulé dans une petite couche API maison (base URL, headers, gestion d'erreurs, parsing JSON) plutôt qu'appelé brut dans les composants. Pas de dépendance HTTP superflue tant que `fetch` suffit.
- **Si le projet grossit** (intercepteurs, refresh de token, retry/backoff, upload avec progression, annulation systématique, multiplication des cas transverses), ne pas hésiter à **proposer Axios** à l'utilisateur, avec l'argumentaire (ce que ça simplifie vs le poids de bundle ajouté). C'est lui qui tranche.
- Si gestion de cache / état serveur nécessaire : TanStack Query.

## Gestion d'état
- Pas de store global par réflexe : `useState`/`useReducer` + contexte local, et TanStack Query pour l'état serveur, couvrent la majorité des cas.
- Si un vrai besoin de store client partagé apparaît, **le proposer à l'utilisateur** au lieu de l'ajouter unilatéralement : **Zustand** par défaut, ou équivalent léger (Jotai, Valtio, Pinia côté Vue) selon le contexte. Justifier le choix ; réserver **Redux Toolkit** aux cas où le besoin est explicitement démontré.

## Routing
- Par défaut, **routing maison** tant qu'il reste léger (poignée de routes, pas de logique transverse) : moins de dépendances, bundle plus petit — cohérent avec la cible VPS 2 Go / 1 vCore.
- Dès que ça devient lourd — routes imbriquées, params typés, lazy-loading par route, guards/redirections d'auth, data loading lié à la route, gestion fine de l'historique —, **proposer le passage à une solution standard** (React Router, TanStack Router, Vue Router...) avec l'argumentaire coût de migration / bénéfice. L'utilisateur tranche.
- Raison structurante : un projet peut finir **public sur GitHub**. Un routing maison qui a dépassé sa zone de confort devient une barrière à l'entrée pour les contributeurs, alors qu'un routeur standard est immédiatement lisible et documenté. Ce critère pèse dans l'arbitrage autant que la technique.

## Outillage qualité
- Toujours Husky + lint-staged + Biome (lint & format) sur les projets front.
- Gestionnaire de paquets : **pnpm exclusivement** (voir `rules/js-ts.md`).

## Mode dev
- **HMR obligatoire** : le dev front tourne avec hot reloading (Vite), état des composants préservé quand le framework le permet. En dev conteneurisé, le HMR doit fonctionner à travers Docker. Voir `rules/js-ts.md`.

## Versions
- **Runtime Node (local, Dockerfile, CI/CD) : dernière version LTS**, jamais `latest` ni version non-LTS.
- **Dépendances front : dernière version majeure stable** (framework, Vite, Biome, TanStack Query...). Vérifier les numéros dans le registre npm avant de les écrire, ne jamais les déduire de mémoire. Voir `rules/versions.md`.

## Build & perf (Vite)
- Cible de déploiement par défaut : **VPS 2 Go de RAM / 1 vCore** (voir `rules/infra.md`). Le build front doit se faire en CI, pas sur le serveur : il peut à lui seul saturer 2 Go.
- Surveiller le poids de bundle : chaque dépendance ajoutée doit être justifiée, code-splitting sur les routes, imports ciblés.
- Activer la compression Brotli en build.
- Si un Dockerfile embarque nginx pour servir le front, optimiser la conf pour réduire le poids de page servie (compression gzip/brotli, cache-control adapté, assets minifiés) — voir aussi le skill `docker-standards`.
- Le score Lighthouse (performance, accessibilité, best practices, SEO) doit être excellent ; vérifier avant de considérer une feature front terminée, quand l'outillage le permet.

## Documentation
- Pour toute feature front complexe, rédiger/maintenir une doc Markdown en anglais, à jour, au niveau d'un architecte senior : le *pourquoi* et les compromis, pas la paraphrase du code. Règle complète : `rules/documentation.md`.
- Documenter en particulier l'architecture de l'app, la gestion d'état, le routing (surtout s'il est maison) et la couche API — avec un `flowchart` ou un `sequenceDiagram` Mermaid quand le flux est plus clair en image.
