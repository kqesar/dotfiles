# Déploiement & sécurité

## Principe : le code peut être public
Concevoir tout déploiement en partant du principe que **le dépôt est public sur GitHub** (ou peut le devenir). La sécurité ne doit jamais reposer sur le fait que le code n'est pas lu. Un projet dont la publication créerait une faille est mal conçu, pas mal partagé.

Corollaire permanent : rien dans le repo ne doit être compromettant. Toute la configuration sensible vit **en dehors** du code, et le repo ne contient que des références et des exemples.

## Secrets
- Jamais de secret en clair dans le repo : ni dans le code, ni dans un `.env` commité, ni dans un `docker-compose.yml`, ni dans un workflow CI, ni dans un Dockerfile (`ARG`/`ENV` finissent dans l'historique de l'image et dans `docker history`).
- Le repo contient un `.env.example` documenté, avec des valeurs factices ; les vraies valeurs vivent dans les secrets GitHub Actions côté CI et dans un `.env` non versionné (permissions `600`) ou un gestionnaire de secrets côté serveur.
- Vérifier le `.gitignore` (`.env`, `*.pem`, clés, dumps) avant tout premier commit ou toute mise en public d'un repo.
- Si un secret a déjà été commité, le considérer comme **compromis** : le faire révoquer/tourner en priorité. Réécrire l'historique ne suffit pas.
- Ne jamais logger un secret, un token ou un mot de passe.

## Chaîne de déploiement
- Authentification CI → cloud/registry via **OIDC** quand la cible le permet, plutôt qu'une clé longue durée stockée en secret.
- À défaut, un compte de déploiement dédié, aux droits minimaux, avec une clé rotable — jamais des identifiants personnels.
- Restreindre le déclenchement des workflows de déploiement (branche protégée, environnement GitHub avec approbation). Attention aux workflows déclenchés par des PR de forks sur un repo public : ils ne doivent jamais avoir accès aux secrets.
- Épingler les actions tierces (SHA de commit plutôt que tag mouvant) pour limiter le risque de compromission d'une action.

## Durcissement du serveur
Sur le VPS cible (voir `rules/infra.md`), rappeler et proposer les bases quand elles manquent :
- Aucun port de service exposé publiquement à part le reverse proxy : base de données, Redis, dashboards d'observabilité restent sur le réseau Docker interne ou derrière une authentification.
- SSH par clé uniquement, pas de login root direct, pare-feu par défaut fermé.
- HTTPS systématique (Let's Encrypt), en-têtes de sécurité au niveau du reverse proxy.
- Conteneurs en utilisateur non-root, images à jour (voir `rules/versions.md`).
- Sauvegardes de la base testées : une sauvegarde jamais restaurée n'est pas une sauvegarde.

## Posture
Ces points ne sont pas un audit ponctuel : les signaler dès qu'un manque est visible pendant une tâche, avec la correction proposée. Expliquer le risque concret plutôt que citer une règle (voir la posture didactique dans `rules/workflow.md`).
