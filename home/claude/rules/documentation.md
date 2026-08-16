# Documentation technique

## Quand documenter
Documenter dès qu'un lecteur ne peut pas reconstituer l'intention en lisant le code : logique métier non triviale, architecture spécifique, décision non évidente, mécanisme transverse. Le critère est **la complexité pour le lecteur**, pas le nombre de lignes.

Quatre domaines concernés, sans exception :
- **Back** : architecture applicative, modèle de données, flux métier, contrats d'API, jobs/tâches de fond.
- **Front** : architecture de l'app, gestion d'état, routing, couche API, conventions structurantes.
- **Infra** : composition des services, réseau, volumes, budget ressources, observabilité.
- **Déploiement** : chaîne CI/CD, environnements, secrets (leur emplacement, jamais leur valeur), procédure de rollback.

Ne pas documenter le trivial : un CRUD standard, une fonction que son nom explique, ou une redite du code n'ont pas besoin de doc — la doc morte est pire que l'absence de doc.

## Niveau attendu
Écrire comme un **architecte senior qui documente pour ses pairs et pour son successeur** : la doc doit permettre à quelqu'un qui découvre le projet de comprendre le système et de prendre une décision, sans avoir à lire tout le code ni à poser de questions.

- **Toujours en anglais.**
- Répondre au *pourquoi*, pas seulement au *quoi* : contexte, contraintes, alternatives écartées et raison de leur rejet. C'est ce qui manque toujours six mois plus tard.
- Aller du général au détail : vue d'ensemble d'abord, puis les mécanismes.
- Nommer les compromis et les limites connues, y compris celles imposées par l'enveloppe VPS 2 Go / 1 vCore (`rules/infra.md`).
- Ton factuel et dense. Pas de remplissage, pas de superlatifs, pas de paraphrase du code.

## Forme
- Un ou plusieurs fichiers **Markdown**, structurés en titres courts et scannables, dans `docs/` (ou `README.md` si le projet est petit). Découper en plusieurs fichiers dès qu'un document couvre plusieurs sujets distincts, avec un index qui les relie.
- **Diagrammes Mermaid** dès qu'une relation est plus claire en image qu'en prose — ils sont versionnés avec le code et rendus nativement par GitHub. Choisir le type selon l'intention :
  - `flowchart` : architecture, composition de services, flux de décision.
  - `sequenceDiagram` : échanges entre acteurs/services (auth, appels API, webhooks).
  - `erDiagram` : modèle de données et relations.
  - `stateDiagram-v2` : cycle de vie d'une entité (commande, job, session).
  - `gitGraph` : stratégie de branches, si elle sort de l'ordinaire.
- Un diagramme doit montrer le **mécanisme réel** (qui appelle qui, qu'est-ce qui traverse quelle frontière), pas une boîte par dossier. Le légender si les flèches sont ambiguës.
- Compléter avec ce qui se relit vite : tableaux (variables d'environnement, endpoints, ports), extraits de code courts et réellement exécutables, liens vers les fichiers sources concernés.

## Maintenance
- La doc fait partie de la feature : une feature complexe n'est pas terminée tant que sa doc n'est pas écrite ou mise à jour.
- À chaque modification d'un comportement documenté, mettre la doc à jour dans le même lot de changements.
- Si une doc existante est constatée fausse pendant une tâche, le signaler — et proposer la correction plutôt que de laisser passer.
