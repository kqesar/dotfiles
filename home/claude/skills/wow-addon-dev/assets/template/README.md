# AddonTemplate

Starting skeleton for a World of Warcraft **retail** addon (Midnight, patch 12.x).
Blizzard-native APIs only — no Ace3, no external libraries.

## What it demonstrates

- Private addon namespace (`local ADDON_NAME, ns = ...`) with zero accidental globals.
- SavedVariables with defaults back-filling **and versioned schema migrations**.
- The modern options panel: `Settings.RegisterVerticalLayoutCategory`, checkboxes and a
  slider, registered through the current (11.0.2+) `RegisterAddOnSetting` signature.
- Event dispatch through a handler table, where declaring a handler *is* the subscription.
- Correct lifecycle ordering: `ADDON_LOADED` → `PLAYER_LOGIN` → `PLAYER_ENTERING_WORLD`.
- Localisation with an automatic English fallback via metatable.
- Slash commands with help output.
- An off-game test harness (`tests/logic_spec.lua`) that stubs the WoW API and runs under
  plain `lua5.1`. `Core.lua` deliberately holds no frame and no client registration, which is
  what makes it loadable outside the game; every entry point lives in `Events.lua`.
- `ADDON_RESTRICTION_STATE_CHANGED` hook point for Midnight's secret-value restrictions.

## Renaming checklist

Copy the directory, then replace `AddonTemplate` / `ADDONTEMPLATE` / `AddonTemplateDB`
everywhere:

```sh
cp -r ~/.claude/skills/wow-addon-dev/assets/template ~/wd/wow-addons/MyAddon
cd ~/wd/wow-addons/MyAddon
mv AddonTemplate.toc MyAddon.toc

# Directory name, TOC name and SavedVariables name must all agree.
grep -rl 'AddonTemplate\|ADDONTEMPLATE' . | xargs sed -i \
	-e 's/AddonTemplateDB/MyAddonDB/g' \
	-e 's/ADDONTEMPLATE/MYADDON/g' \
	-e 's/AddonTemplate/MyAddon/g' \
	-e 's/addontemplate/myaddon/g' \
	-e 's|/atp|/ma|g'
```

Then, by hand:

1. `## Title`, `## Notes`, `## Author`, `## IconTexture` in the TOC.
2. `## Interface:` — run `bash ~/.claude/hooks/wow-context.sh` for the current value.
3. Slash command aliases in `Core.lua`.
4. The `DEFAULTS` table in `Core.lua` — it is the single source of truth for the config schema.
5. `docs/ARCHITECTURE.md` and `CLAUDE.md`.

## Install for development

```sh
git init
ln -s "$PWD" "$WOW_RETAIL_DIR/Interface/AddOns/MyAddon"
```

The game directory must never hold the source itself: a Battle.net repair wipes anything that
is not a link to a real repository.

## Checks

```sh
luacheck .
stylua --check .
lua5.1 tests/logic_spec.lua
```

`tests/` is not listed in the TOC, so the client never loads it. Add one scenario per decision
branch — and one per regression you fix, which is where the harness earns its keep.

Both are also run automatically on every file write by the `wow-lint.sh` Claude Code hook.
