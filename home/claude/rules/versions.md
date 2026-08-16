# Politique de versions

## Runtimes, images Docker et CI/CD → LTS uniquement
- Toute image de base Docker, tout runtime et toute version déclarée dans une CI/CD (GitHub Actions, GitLab CI, etc.) doit utiliser la **dernière version LTS** disponible du langage/runtime concerné (Node, Java, Python, PostgreSQL, etc.).
- Ne jamais utiliser une version `current`/non-LTS, ni une version LTS en fin de vie (EOL), sauf contrainte explicite du projet — dans ce cas, la documenter.
- Épingler la version de façon lisible (ex: `node:24-alpine`, `actions/setup-node@v5` avec `node-version: 24`), pas de tag `latest` flottant.

## Librairies back et front → dernière version majeure
- Les dépendances applicatives (back et front) doivent être sur leur **dernière version majeure stable**.
- Ne pas installer une version majeure `-beta`/`-rc` sauf demande explicite de l'utilisateur.
- Si une montée de version majeure implique un breaking change non trivial, ne pas l'appliquer unilatéralement : présenter à l'utilisateur le coût de migration et les alternatives, et le laisser trancher.

## Vérifier avant d'écrire un numéro de version
- **Ne jamais déduire un numéro de version de la mémoire du modèle** : elle est périmée par construction. Vérifier la version réelle au moment de l'écriture (registre npm/PyPI/Maven, page LTS officielle du runtime, Docker Hub, `npm view <pkg> version`, WebFetch/WebSearch).
- En cas d'échec de récupération, le dire explicitement à l'utilisateur plutôt que d'écrire un numéro incertain.

## Audit à l'ouverture d'une session sur un repo
- À l'ouverture d'une session Claude dans un repo, vérifier si les **images Docker** (`Dockerfile`, `docker-compose*.yml`) et les **définitions CI/CD** (`.github/workflows/`, `.gitlab-ci.yml`, etc.) utilisent des versions obsolètes ou non-LTS.
- Si des mises à jour existent, **signaler et proposer la modification** : versions actuelles → cibles, risques de breaking change. Ne rien modifier sans validation.
- Contrôle unique par session, concis, non bloquant : signaler, puis continuer la tâche demandée.
