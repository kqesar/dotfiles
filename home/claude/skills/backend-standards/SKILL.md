---
name: backend-standards
description: Use this skill whenever writing, reviewing, or architecting back-end/server code — APIs, services, workers, data/persistence layer — in any language. Enforces the user's standing conventions for readable architecture, KISS/SOLID, comment discipline, CPU/RAM economy on a 2GB/1vCore VPS, LTS runtimes and latest-major dependencies, pnpm-only and HMR-in-dev for JS/TS stacks, and when to proactively propose an evolution of the architecture, the database schema, or the infra stack (cache, queue, logging/observability) — didactically, since the user is moving up from PHP monolith/CRUD into modern back-end and infra. Trigger on server-side source files, API route/controller/service/repository files, back-end project scaffolding, or any request to build/modify a back-end.
---

# Back-end standards

## Architecture
- Garder une architecture lisible ; respecter KISS et SOLID tant qu'ils restent pertinents pour le contexte — ne pas les appliquer de façon dogmatique si ça complexifie inutilement une chose simple.

## Commentaires
- Commentaires en anglais, uniquement pour les éléments réellement complexes (contrainte cachée, invariant non évident, contournement d'un bug spécifique). Ne pas commenter ce qu'un code bien nommé exprime déjà.

## Outillage (stack JS/TS)
- Gestionnaire de paquets : **pnpm exclusivement**.
- **HMR obligatoire en dev** : le serveur redémarre/recharge automatiquement au changement de fichier (watch mode natif, `tsx watch`, `nodemon`...). Pas de redémarrage manuel dans la boucle de dev. Voir `rules/js-ts.md`.

## Versions
- **Runtime : dernière version LTS** (Node, Java, Python, PostgreSQL...), aussi bien en local que dans le Dockerfile et la CI/CD.
- **Dépendances : dernière version majeure stable.** Vérifier les numéros dans le registre avant de les écrire, ne jamais les déduire de mémoire. Une montée de majeure avec breaking change non trivial se propose, elle ne s'applique pas unilatéralement. Voir `rules/versions.md`.

## Performance & ressources
- Cible de déploiement par défaut : **VPS 2 Go de RAM / 1 vCore** (voir `rules/infra.md`). 1 seul cœur : pas de parallélisme réel, ne pas bloquer la boucle d'événements avec du CPU-bound synchrone. RAM partagée avec la base et le reverse proxy.
- Le code doit être économe en CPU et en RAM, à la fois à l'exécution et lors du traitement des requêtes (éviter allocations inutiles, requêtes N+1, polling agressif, boucles superflues, caches mémoire non bornés).
- Tout service d'infra supplémentaire (Redis, broker, moteur de recherche...) doit être chiffré en RAM et comparé à l'alternative la plus légère. Cette contrainte cadre la proposition, elle ne l'interdit pas.

## Évolution d'architecture & d'infra
- Si l'architecture actuelle montre ses limites, le signaler proactivement à l'utilisateur avec plusieurs choix possibles et une argumentation complète (avantages/inconvénients, coût de migration, risques) pour qu'il tranche. Ne jamais faire évoluer l'architecture unilatéralement sans validation.
- **Base de données** : proposer sans hésiter les évolutions que le besoin justifie (index manquants, schéma à revoir, types de colonnes, dénormalisation ciblée, changement de moteur), toujours avec un plan de migration concret et réversible.
- **Services & observabilité** : être force de proposition sur l'ajout d'un cache/file d'attente (Redis, Valkey) ou d'une stack de logs/métriques, après avoir vérifié que la brique existante ne couvre pas déjà le besoin (PostgreSQL fait du full-text, du JSONB, du LISTEN/NOTIFY, et des files correctes à petite échelle). Détail des options et de leur coût mémoire : `rules/infra.md`.
- **Prérequis d'observabilité côté code**, gratuits en RAM : logs structurés JSON, niveaux cohérents, identifiant de corrélation par requête, aucun secret ni donnée personnelle loggé.
- **Posture** : l'utilisateur vient du PHP monolithique/CRUD et veut monter en compétence sur le back et l'infra — proposer et expliquer le *pourquoi*, sans décider à sa place (voir `rules/workflow.md`).

## Documentation
- Pour toute feature back complexe, rédiger/maintenir une doc Markdown en anglais, à jour, au niveau d'un architecte senior : le *pourquoi* et les compromis, pas la paraphrase du code. Règle complète : `rules/documentation.md`.
- Diagrammes Mermaid quand ils clarifient : `flowchart` pour l'architecture et les flux, `sequenceDiagram` pour les échanges entre services (auth, webhooks), `erDiagram` pour le modèle de données, `stateDiagram-v2` pour le cycle de vie d'une entité.
- Documenter en particulier le modèle de données, les contrats d'API et les jobs de fond — et mettre la doc à jour dans le même lot de changements que le code.
