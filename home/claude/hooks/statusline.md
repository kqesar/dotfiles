# Claude Code status line

What `statusline.sh` (next to this file) displays, and two ways to reproduce it
on another machine: copy the script, or have Claude Code generate an
equivalent one with `/statusline`.

```
Opus 5.5 high ultracode  dotfiles  ⎇ master  ctx 34%  5h 62% ↻ 2h13  7j 85% ↻ 3j04h
```

| Segment | Source | Notes |
|---|---|---|
| `Opus 5.5` (bold) | `.model.display_name` | |
| `high` (dim) | `.effort.level` | Live value, follows `/effort`. Absent on models without effort support. |
| `ultracode` (cyan) | `ultracode` key in the settings files | Not part of the status line JSON — see [Limits](#limits). |
| `dotfiles` | basename of `.workspace.current_dir` | |
| `⎇ master` (magenta) | `git symbolic-ref`, short SHA when detached | Hidden outside a repository. |
| `ctx 34%` | `.context_window.used_percentage` | Can be `null` early in a session; the segment is then hidden. |
| `5h 62% ↻ 2h13` | `.rate_limits.five_hour.*` | Usage, then time until the window resets. |
| `7j 85% ↻ 3j04h` | `.rate_limits.seven_day.*` | Same, weekly window (`j` = days). |

Percentages are green below 50, yellow below 80, red from 80 on.

## How it works

Claude Code runs the configured command after each assistant message (and a
few other events), pipes a JSON description of the session to its stdin, and
displays what it prints. Field reference:
<https://code.claude.com/docs/en/statusline>.

The script makes a single `jq` call that extracts every field as one TSV row,
instead of one `jq` per field: the command runs often, and each process spawn
is visible latency on a small machine.

`refreshInterval: 60` re-runs it every minute even when the session is idle.
Without it, the `↻` countdowns would freeze between messages.

## Option 1 — copy the script

Prerequisites: `bash`, `jq`, `git`, a terminal with ANSI colours and UTF-8.

1. Copy [`statusline.sh`](statusline.sh) to `~/.claude/hooks/statusline.sh`
   (any path works; adjust the command below).
2. Add this to `~/.claude/settings.json`:

   ```json
   "statusLine": {
     "type": "command",
     "command": "bash \"$HOME/.claude/hooks/statusline.sh\"",
     "refreshInterval": 60
   }
   ```

3. Send any message: the line appears under the prompt.

Calling it through `bash` means the file needs no executable bit, which
survives copies and checkouts that drop permissions.

On a machine set up with these dotfiles, there is nothing to do: `dots link`
already links `~/.claude/hooks/` and `~/.claude/settings.json`.

## Option 2 — let Claude Code generate it

`/statusline` takes a natural-language description, writes a script under
`~/.claude/` and updates `settings.json` itself. Paste one of these prompts.
The result will not be byte-identical, but it covers the same segments.

English:

```
/statusline A bash script using a single jq call, showing on one line: the model display name in bold; the effort level (.effort.level) dimmed, if present; "ultracode" in cyan when the `ultracode` key is true in ~/.claude/settings.json, <cwd>/.claude/settings.json or <cwd>/.claude/settings.local.json (last one defining it wins); the basename of the current directory; the git branch in magenta prefixed with ⎇ (short SHA if detached, hidden outside a repo); "ctx N%" from context_window.used_percentage; "5h N%" and "7j N%" from rate_limits.five_hour and rate_limits.seven_day, each followed by "↻" and the time left until resets_at (epoch seconds) formatted as 3j04h, 2h13 or 12min. Colour every percentage green below 50, yellow below 80, red otherwise. Hide any segment whose field is absent. Set refreshInterval to 60 so the countdowns keep moving.
```

Français :

```
/statusline Un script bash avec un seul appel à jq, qui affiche sur une ligne : le nom du modèle en gras ; le niveau d'effort (.effort.level) en grisé s'il existe ; « ultracode » en cyan quand la clé `ultracode` vaut true dans ~/.claude/settings.json, <cwd>/.claude/settings.json ou <cwd>/.claude/settings.local.json (le dernier qui la définit l'emporte) ; le nom du dossier courant ; la branche git en magenta précédée de ⎇ (SHA court si HEAD détachée, masquée hors dépôt) ; « ctx N% » depuis context_window.used_percentage ; « 5h N% » et « 7j N% » depuis rate_limits.five_hour et rate_limits.seven_day, chacun suivi de « ↻ » et du temps restant avant resets_at (secondes epoch) au format 3j04h, 2h13 ou 12min. Chaque pourcentage en vert sous 50, jaune sous 80, rouge au-delà. Masquer tout segment dont le champ est absent. Mettre refreshInterval à 60 pour que les comptes à rebours avancent.
```

## Limits

- **Rate limits** only exist for claude.ai Pro and Max subscribers, and only
  after the first API response of the session. With an API key, the `5h` and
  `7j` segments never show.
- **Ultracode** is not exposed in the status line JSON, so the script reads the
  `ultracode` key from the settings files instead. A session-only
  `/effort ultracode` is therefore invisible to it.
- The time left is computed against the local clock: a skewed clock skews the
  countdowns.
