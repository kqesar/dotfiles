# Cible de déploiement

## Hypothèse par défaut : petit VPS
Sauf indication contraire du projet, considérer que le back, le front et les conteneurs Docker tournent sur un **VPS de 2 Go de RAM et 1 vCore**. Cette hypothèse reste valable même si le serveur est upgradé plus tard : on conçoit pour cette enveloppe.

## Conséquences concrètes
- **RAM** : budget serré, tout compris (app + base de données + reverse proxy + build éventuel). Éviter les runtimes gourmands, les caches en mémoire non bornés, le chargement complet de gros datasets.
- **CPU** : 1 seul cœur → pas de parallélisme réel. Éviter le polling agressif, les tâches CPU-bound synchrones qui bloquent la boucle d'événements, les workers/threads multiples par défaut.
- **Builds** : ne pas builder sur le serveur si évitable (build en CI, image finale légère). Un build front/back complet peut à lui seul saturer 2 Go.
- **Stack** : privilégier les solutions légères. Un service supplémentaire (Redis, moteur de recherche, broker...) doit toujours être chiffré en RAM et comparé à l'alternative la plus légère — cette contrainte encadre la proposition, elle ne l'interdit pas (voir ci-dessous).
- **Limites conteneurs** : définir des `mem_limit`/`cpus` cohérents avec l'enveloppe et laisser de la marge pour l'OS.

## Arbitrage
Si une feature demandée ne tient pas dans cette enveloppe, le dire à l'utilisateur avec les options (dégrader la feature, alléger la stack, upgrader le VPS) et le laisser trancher — voir `rules/workflow.md`.

# Force de proposition sur l'infra

Le budget serré n'est **pas** une consigne d'immobilisme. Sur ce sujet, la posture attendue est proactive : détecter le besoin, le nommer, proposer, expliquer — puis laisser l'utilisateur trancher.

## Base de données
- Si le schéma, le moteur ou la stratégie d'accès ne correspondent plus au besoin, **le proposer sans hésiter** : normalisation ou dénormalisation ciblée, index manquants, changement de type de colonne, table de jointure, partitionnement, passage d'un stockage JSON à des colonnes typées (ou l'inverse), changement de moteur.
- Toujours accompagner d'un plan de migration concret : script/migration, réversibilité, impact sur les données existantes, downtime éventuel.
- Ne jamais appliquer une évolution de schéma non triviale sans validation explicite.

## Services d'infra additionnels
- Quand le besoin est réel, **proposer activement** l'ajout d'un composant : cache/sessions/rate-limiting/file d'attente (Redis, Valkey), recherche full-text, broker de messages, scheduler, stockage objet.
- Toujours vérifier d'abord si la brique déjà en place couvre le besoin (ex : PostgreSQL fait du full-text, du JSONB, du LISTEN/NOTIFY et des files d'attente correctes à petite échelle). Ajouter un service se justifie, il ne se réflexe pas.
- Format de la proposition : besoin constaté → options (dont l'option « ne rien ajouter ») → coût RAM/CPU réel de chacune dans l'enveloppe 2 Go → recommandation argumentée.

## Logs & observabilité
- Proposer proactivement une stack de logs/métriques dès qu'un projet dépasse le stade jouet : sans observabilité, un incident en production est indébogable.
- Présenter l'échelle des options, du plus léger au plus lourd, avec le coût mémoire de chacune : logs structurés JSON + `docker logs`/journald → visualiseur léger (Dozzle) → Grafana + Loki + Promtail → Graylog → stack Elasticsearch/OpenSearch.
- Dire franchement quand une option ne rentre pas dans 2 Go : une stack Elasticsearch complète y est irréaliste, Graylog (Elastic + MongoDB) aussi. Loki reste raisonnable ; un collecteur qui pousse vers un service managé externe (free tier) est souvent le meilleur rapport valeur/RAM sur ce type de VPS.
- Rappeler les prérequis applicatifs qui ne coûtent rien : logs structurés, niveaux cohérents, identifiant de corrélation par requête, rotation, et **aucun secret ni donnée personnelle dans les logs**.
