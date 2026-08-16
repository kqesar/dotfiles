---
name: docker-standards
description: Use this skill whenever writing or reviewing Dockerfiles, docker-compose files, CI/CD pipelines, container resource limits, or nginx configs used inside a container. Enforces the user's standing conventions for LTS-only base images, CPU/RAM-economical container deployments targeting a 2GB/1vCore VPS, page-weight optimization when nginx serves front-end assets, secret/port hygiene for repos that may be public, and pnpm/HMR-through-Docker conventions for JS/TS projects. Trigger on Dockerfile, docker-compose.yml, .github/workflows, .gitlab-ci.yml, nginx.conf in a container context.
---

# Docker standards

## Versions
- **Images de base et runtimes CI/CD : dernière version LTS uniquement**, jamais `latest` flottant ni version non-LTS/EOL. Vérifier la version réelle avant de l'écrire (Docker Hub, page LTS officielle) — voir `rules/versions.md`.
- À l'ouverture d'une session sur un repo, contrôler les versions des images Docker et des workflows CI/CD, et proposer la mise à jour si elles sont obsolètes.

## Ressources
- Cible de déploiement par défaut : **VPS 2 Go de RAM / 1 vCore** (voir `rules/infra.md`). Dimensionner les `mem_limit`/`cpus` en conséquence, en gardant de la marge pour l'OS.
- Les déploiements Docker doivent être économes en CPU et en RAM : images légères, build multi-stage, base images alpine/distroless quand c'est pertinent pour le langage, pas de process superflu dans le conteneur final.
- Ne pas builder sur le serveur cible si c'est évitable : builder en CI et déployer une image finale minimale.
- Si une conf nginx sert des assets front dans le conteneur, l'optimiser pour réduire le poids de page servie (compression gzip/brotli, cache-control adapté, assets minifiés) — cohérent avec les exigences de score Lighthouse du front (voir le skill `frontend-standards`).

## Sécurité (le repo peut être public)
- **Aucun secret dans le repo** : ni dans le `docker-compose.yml`, ni en `ARG`/`ENV` d'un Dockerfile (ils restent dans l'historique de l'image, lisible via `docker history`), ni dans un workflow CI. `.env.example` versionné avec des valeurs factices, `.env` réel jamais commité.
- **Ne pas publier de ports inutiles** : base de données, Redis, dashboards d'observabilité restent sur le réseau Docker interne ; seul le reverse proxy est exposé. Si un port doit sortir, le binder sur `127.0.0.1`.
- Conteneurs en utilisateur **non-root**, système de fichiers en lecture seule quand c'est possible.
- Détail de la chaîne de déploiement et du durcissement serveur : `rules/deployment.md`.

## Documentation infra & déploiement
- Toute infra non triviale se documente en Markdown/anglais (voir `rules/documentation.md`) : composition des services, réseau et ports, volumes et données persistées, budget RAM/CPU par conteneur, procédure de déploiement et de rollback.
- Un `flowchart` Mermaid de la topologie (internet → reverse proxy → services → base/volumes) et un tableau des variables d'environnement (nom, rôle, où vit la valeur — **jamais la valeur**) valent mieux que des paragraphes.

## Projets JS/TS
- Installation des dépendances avec **pnpm exclusivement** : Corepack activé dans l'image, `pnpm install --frozen-lockfile`, `pnpm-lock.yaml` copié en amont pour préserver le cache de layers, store pnpm mis en cache entre les builds CI.
- **Compose de dev : HMR fonctionnel à travers le conteneur** — sources montées en volume, `node_modules` isolé du host, port du client HMR exposé. N'activer le polling du watcher que si l'inotify du host ne remonte pas dans le conteneur : il coûte du CPU sur 1 vCore. Voir `rules/js-ts.md`.
- Garder les stages dev et prod séparés : le HMR et l'outillage de dev ne doivent jamais atterrir dans l'image de production.
