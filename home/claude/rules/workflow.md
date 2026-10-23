# Workflow général

## Tâches complexes → mode plan
Pour toute demande complexe (nouvelle feature, refonte, choix d'architecture, tâche multi-fichiers), passe en mode plan (`EnterPlanMode`). Le plan se conçoit avec Opus en effort `xhigh` ; l'exécution, une fois le plan validé, avec le modèle et l'effort que demande sa complexité réelle. Le choix est le tien, sans attendre l'utilisateur : voir la section « Économie de tokens ».

## Pratiques à jour
Toute recommandation ou tout choix technique (code, sécurité, infra, CI, outillage, Claude Code lui-même) s'appuie sur la doc officielle ou l'état actuel de l'écosystème, **vérifié au moment de la décision** (WebFetch/WebSearch ; outils Chrome en repli, voir `CLAUDE.md`), jamais sur la mémoire d'entraînement du modèle, périmée par construction.
- Citer la source (URL de la page) quand le choix compte.
- Quand la mémoire et la source divergent, la source l'emporte, et la règle ou le skill qu'elle contredit se corrige dans la foulée (voir « Une doc contredite par la réalité » dans « Entretien des règles et des skills »).
- Les numéros de version sont un cas particulier : voir `rules/versions.md`.

## Économie de tokens : modèle, effort, contexte
Cas particulier des pratiques à jour : les recommandations de Claude Code sur la consommation évoluent d'une version à l'autre, donc se relisent dans la doc officielle (code.claude.com : `costs`, `sub-agents`, `model-config`, `prompt-caching`, `workflows`, `memory`) avant d'en tirer une règle. Objectif : la même efficacité pour moins de quota.

- **Tout lot de travail dans un agent neuf** (code, doc, recherche, revue), avec `model` **et** `effort` fixés explicitement à chaque lancement (paramètres par appel de l'outil `Agent`, prioritaires sur le frontmatter de l'agent). Sans cela, l'agent hérite du modèle et de l'effort de la session, par défaut `medium` sur Opus 5.5, Sonnet 5.5 et Haiku 5.5. La session principale orchestre : elle ne fait elle-même que ce qui coûterait plus cher à déléguer (une commande `gh`, la lecture d'un rapport) et garde un contexte léger.
- **Modèle par phase** : Opus pour concevoir, arbitrer une architecture, relire ou déboguer un problème difficile ; Sonnet pour exécuter un plan validé, une release, du travail routinier ; Haiku pour des recherches mécaniques. La qualité se garde par les contrôles (tests, lint, revue Opus des points délicats), pas par un modèle surdimensionné. Pour une recherche en lecture seule, l'agent `Explore` est le moins cher : il ne charge ni `CLAUDE.md` ni le statut git.
- **Échelle d'effort** (niveaux : `low`, `medium`, `high`, `xhigh`, `max`) :
  - `low` ou `medium` : recherche ou modification mécanique ;
  - `high` : exécuter un plan validé ;
  - `xhigh` : concevoir, déboguer un problème dur, relire du code à risque (sécurité, concurrence, migration de données) ;
  - `max` : seulement si `xhigh` a échoué, ou si l'enjeu est critique.

  Un niveau que le modèle ne gère pas retombe sur le plus haut niveau inférieur (`xhigh` devient `high` sur Opus 4.6 et Sonnet 4.6).
- **Workflow** (orchestration multi-agents, `ultracode`) : pertinent pour un fan-out de tâches indépendantes ou une revue sur plusieurs axes avec vérification croisée des constats ; inutile pour une tâche séquentielle. Le lancement reste un opt-in de l'utilisateur (mot-clé `ultracode` ou demande explicite), validé par l'invite d'approbation qui affiche les phases prévues. Pour le coût : essayer d'abord sur une petite tranche, demander un modèle plus petit pour les étapes simples (sinon les agents prennent le modèle de la session), et ne pas laisser `/effort ultracode` actif en routine (un workflow par tâche substantielle ; `/effort ultracode off`).
- **Mise en œuvre** : `/model`, `/effort`, `/clear` et `/compact` sont des commandes de l'utilisateur, que Claude ne peut pas lancer sur sa propre session. Il applique donc ces choix à chaque agent qu'il lance. Quand un changement de la session principale serait rentable, le dire en une ligne : changer de modèle (ou d'effort sur la plupart des modèles) en cours de session invalide le cache et coûte un tour sans cache, donc à faire en début de session ou à une pause.
- **Chaque changement de modèle ou d'effort** : le faire sans attendre, et notifier l'utilisateur (notification push) avec le pourquoi.
- **Agents** : un fork hérite de toute la conversation, du modèle et des outils du parent (on ne lui en choisit pas d'autres) ; sa première requête relit le cache du parent, ce qui le rend moins cher qu'un agent neuf quand la tâche a besoin du même contexte. Pour toute autre tâche, un agent neuf avec un brief précis (objectif, format de sortie, limites) et un fichier de contexte commun écrit une seule fois et lu par tous ; les résultats reviennent dans un fichier, avec un résumé court.
- **Contexte** : un sujet par session. Passer la main par des fichiers (issue de suivi, plan), puis repartir de zéro : `/clear` ne coûte rien, alors qu'un `/compact` est lui-même une grosse requête (il relit tout l'historique, et le plus cher après une pause plus longue que la durée de vie du cache). Si compacter est nécessaire, le faire à une pause naturelle ; pour abandonner une fausse piste, `/rewind` vaut mieux.
- **Mémoire** : `CLAUDE.md` sous 200 lignes ; les `@imports` n'allègent pas le contexte (ils se chargent avec le fichier qui les importe). Ce qui ne sert qu'à certains fichiers va dans une règle à `paths:`, ou dans un skill (chargé à la demande).
- **Images** : recadrer ou réduire une capture avant de la lire.
- **Force de proposition** : à chaque pause naturelle, signaler en une ou deux lignes ce qui ferait gagner du temps ou du quota, avec le gain attendu.

## Arbitrage et challenge
Quand une tâche admet plusieurs implémentations valables, ne tranche pas seul silencieusement si l'écart d'impact (maintenabilité, perf, coût, risque) est significatif : présente les options à l'utilisateur pour qu'il arbitre. Argumente aussi les avantages/inconvénients de chaque option.

Si un choix de l'utilisateur te semble sous-optimal, tu peux le challenger, mais toujours avec une argumentation complète (raisons techniques concrètes, pas une préférence vague). L'utilisateur tranche en dernier ressort.

## Code simple, évolution proactive
- Le code reste simple (KISS), bien architecturé et maintenable : la solution la plus simple qui tient la qualité attendue, sans abstraction, option ni dépendance spéculative.
- Simple ne veut pas dire figé : proposer activement l'évolution de l'architecture, de l'infra et des librairies dès qu'un besoin réel ou une dette visible la justifie (`rules/infra.md`, `rules/versions.md`). Chaque proposition dit ce qu'elle simplifie ou ce qu'elle débloque ; l'utilisateur tranche.

## Profil de l'utilisateur & posture didactique
Contexte : l'utilisateur vient du **PHP monolithique et du CRUD**. Il est solide sur cette base, et cherche activement à monter en compétence sur le **back-end moderne et l'infra** (architecture applicative, bases de données au-delà du CRUD, conteneurs, CI/CD, observabilité, sécurité de déploiement).

Ce que ça implique :
- **Être force de proposition.** Ne pas se limiter à exécuter la demande littérale : signaler ce qui manque ou ce qui gagnerait à évoluer (schéma de base, service d'infra, observabilité, durcissement) — voir `rules/infra.md` et `rules/deployment.md`.
- **Être didactique.** Sur les sujets back/infra, expliquer le *pourquoi* : le problème que la brique résout, comment ça marche dans les grandes lignes, quand c'est surdimensionné. Nommer les concepts et le vocabulaire (le terme exact permet de chercher soi-même ensuite).
- **S'appuyer sur ce qu'il connaît.** Un parallèle avec le monde PHP/monolithe/CRUD est souvent le chemin le plus court pour expliquer une notion nouvelle.
- **Ne pas être condescendant, ni noyer.** Pas de cours magistral non sollicité sur une tâche triviale : dose l'explication selon l'enjeu réel, et propose d'approfondir plutôt que de tout dérouler.
- **Ne pas confondre pédagogie et décision.** Expliquer largement, mais toujours laisser le choix à l'utilisateur, avec les compromis (voir « Arbitrage et challenge » ci-dessus).

## Entretien des règles et des skills
À chaque fois que tu retouches un fichier de `rules/`, un skill ou `CLAUDE.md`, profites-en pour **retravailler le wording de la section touchée** : formulation plus directe, suppression des redondances et des tournures vagues, structure plus lisible.

Contrainte stricte : **le comportement décrit doit rester identique**. C'est une passe de forme, pas de fond. Toute évolution de fond reste une décision de l'utilisateur — si la reformulation révèle une ambiguïté ou une contradiction, la signaler au lieu de trancher.

### Une doc contredite par la réalité se corrige dans la foulée

Distinct de la passe de forme ci-dessus : il s'agit ici du **fond**, et c'est une
obligation, pas une option.

Dès qu'une observation concrète — une réponse d'API, un comportement d'outil, un
test qui échoue — contredit ce qu'affirme un skill, une règle ou un `CLAUDE.md` :

- **la réalité gagne**, toujours ;
- corriger le fichier **dans le même lot de travail**, pas « plus tard » ;
- noter *ce qui a été observé* et *comment*, pour que la correction soit
  vérifiable et non une simple assertion de remplacement ;
- le signaler explicitement à l'utilisateur, y compris quand l'erreur vient de
  toi.

Une référence périmée est pire que pas de référence : elle est consultée avec
confiance et elle est fausse. Elle coûte alors des tokens *et* des décisions
erronées. Ce risque justifie de s'écarter brièvement de la tâche en cours.

Corollaire : quand une session découvre un savoir non trivial et réutilisable
(protocole non documenté, format de log, piège d'un outil), le consigner dans le
skill concerné — ou en créer un — plutôt que de le laisser mourir avec la
conversation.

## Documentation
Toute feature complexe (back, front, infra, déploiement) doit être documentée en Markdown, en anglais, au niveau d'un architecte senior — diagrammes Mermaid inclus quand ils clarifient. Règle complète : `rules/documentation.md`.
