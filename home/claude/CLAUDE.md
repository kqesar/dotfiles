@RTK.md

<!-- Les fichiers de rules/ se chargent seuls depuis ~/.claude/rules : à chaque session sans frontmatter `paths:`, à la demande avec. Les réimporter ici ne sert à rien. -->

# Fallback navigation web

Si WebFetch échoue sur un lien (erreur, 403, contenu bloqué…), lire la page avec les outils Chrome (`mcp__claude-in-chrome__*`) avant d'abandonner ou de répondre de mémoire.

# Navigateur piloté : playwright-cli

Pour piloter une page web, tester une UI ou en prendre des captures, utiliser `playwright-cli`, installé en global avec pnpm, plutôt qu'écrire un script Playwright à usage unique. Son skill `playwright-cli` donne les commandes, et `playwright-cli --help <commande>` le détail. Chromium et Firefox sont installés. Sans option, `open` cherche Google Chrome, qui n'est pas installé : toujours passer `--browser=chromium` (ou `firefox`). WebKit ne démarre pas en natif sur cette machine : il tourne dans l'image Docker officielle de Playwright, avec la recette donnée dans le skill. Pour mettre l'outil à jour : `pnpm add -g @playwright/cli@<version vérifiée>`, puis `playwright-cli install-browser <navigateur>`.
