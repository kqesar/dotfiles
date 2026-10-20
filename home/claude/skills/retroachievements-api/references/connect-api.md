# Connect API (`dorequest.php`) — standalone integrations

The **write** side of RetroAchievements. Used by emulators and by "standalone" integrations (a game or server that awards RA achievements natively, e.g. a private MMO server). Not needed for read-only projects.

- Single non-REST endpoint: `https://retroachievements.org/dorequest.php`
- The `r` query param selects the function (`login2`, `startsession`, `ping`, `awardachievement`, `awardachievements`, plus the emulator-only `patch` and `codenotes2` — see the last section).
- Separate credential from the Web API key: a **Connect token** (`t`), obtained with `r=login2`.
- Officially private and locked down; the documented subset below is what standalone integrations are allowed to use. Anything else (emulator-only calls) is not public API and will change without notice.

## Prerequisites

- A dedicated RA account for the integration (e.g. `OldSchoolRunescape`) — not a personal account.
- One or more game pages on the **Standalones** console, created by the RA admin team (DM the `RAdmin` user).
- Achievements created on that game page (an admin/dev does this); you need their IDs.
- Your Web API key **and** your Connect token.

## Mandatory user agent

**Always send a `User-Agent` header on every `dorequest.php` call.** Format:

```
{Frontend/Standalone name}/{x.y.z Version} ({platform}) {Integration/x.y.z} {core information}
```

Example: `HorizonXI/1.0.0 (Server)`. Requests without a user agent are considered abusive.

## Secrets

The Connect token is **more sensitive than the Web API key** — it can grant achievements in your integration's name. Env var / secret manager only, never in the repo, never in a client binary or browser bundle (`rules/deployment.md`). If it leaks, rotate it by logging in again and treat past unlocks as suspect.

---

## `r=login2` — get the Connect token

`GET https://retroachievements.org/dorequest.php?u=YourUsername&p=YourPassword&r=login2`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | integration account username |
| `p` | yes | integration account password |
| `r` | yes | `login2` |

```json
{
  "Success": true,
  "User": "OldSchoolRunescape",
  "Token": "4AotgGxjIH5iT1gz",
  "Score": 1,
  "SoftcoreScore": 0,
  "Messages": 0,
  "Permissions": 1,
  "AccountType": "Registered"
}
```

Store `Token` securely. Call this once at setup (or on rotation), not per request — it takes the account password.

---

## Linking a player's RA account

OAuth2 is planned but not production-ready. Current flow:

1. Ask the player for their RA username.
2. Generate a GUID/key and ask them to paste it into their **account motto** at `https://retroachievements.org/controlpanel.php`.
3. Player confirms.
4. Verify via the Web API `API_GetUserProfile?u=<username>` that `Motto` contains your key.

Mottos are capped at **50 characters**. Remind the player to reset their motto afterwards. Persist the `ULID` from the profile response, not the username (usernames are mutable).

---

## `r=startsession` — player begins playing

`POST https://retroachievements.org/dorequest.php?u=YourUsername&t=YourConnectToken&r=startsession&g=YourCoreGameId&k=TheirUsername`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | integration account username |
| `t` | yes | Connect token |
| `r` | yes | `startsession` |
| `g` | yes | your **primary** game ID (never a bonus/subset ID) |
| `k` | yes | the player's RA username (already linked via motto) |

```json
{
  "Success": true,
  "HardcoreUnlocks": [ { "ID": 141, "When": 1591132445 } ],
  "ServerNow": 1704076711
}
```

`HardcoreUnlocks` tells you what the player already has — use it to reconcile your local state instead of re-awarding. `When` and `ServerNow` are **epoch seconds**; trust `ServerNow` over the client clock.

---

## `r=ping` — heartbeat (every ~2 minutes)

`POST https://retroachievements.org/dorequest.php?u=YourUsername&t=YourConnectToken&r=ping&g=YourCoreGameId&k=TheirUsername`

Query params: same as `startsession` with `r=ping`.

Multipart form-data payload:

| Field | Req | Description | Example |
| :-- | :-- | :-- | :-- |
| `m` | no | the player's current rich presence string | `Level 30 • Running around in San d'Oria` |

```json
{ "Success": true }
```

Emulators ping every 2 minutes. Pings keep the player in the game's active-player list, keep the game on the player's profile and on the site's trending/active lists, and publish the rich presence string. Strongly encouraged, not mandatory. On a 1 vCore VPS (`rules/infra.md`), batch these on a single timer over your active players rather than one timer per player.

---

## `r=awardachievement` — unlock one achievement

`POST https://retroachievements.org/dorequest.php?u=YourUsername&t=YourConnectToken&r=awardachievement&k=TheirUsername&a=9&v=<md5>&h=1`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | integration account username |
| `t` | yes | Connect token |
| `r` | yes | `awardachievement` |
| `k` | yes | player's RA username |
| `a` | yes | achievement ID |
| `h` | yes | 1 = hardcore ("no cheats"), 0 = softcore |
| `v` | yes | verification hash, see below |

Verification hash:

```
v = md5(achievementId + theirUsername + hardcore + achievementId)
// md5("9TheirUsername19") == "8f48cd6a05f875bf4c2818aec03523c1"
```

Note the achievement ID appears **twice**, first and last, with no separators.

```json
{
  "Success": true,
  "AchievementsRemaining": 5,
  "Score": 22866,
  "SoftcoreScore": 5,
  "AchievementID": 9
}
```

`AchievementsRemaining` counts what is left for that player on the achievement's game. `Score`/`SoftcoreScore` are the player's new site-wide totals.

---

## `r=awardachievements` — unlock many / resync

Use this for batches and for reconciling a player's full unlock list. Note the plural `r` value, and that `a`, `h`, `v` move **into the multipart body**.

`POST https://retroachievements.org/dorequest.php?u=YourUsername&t=YourConnectToken&r=awardachievements&k=TheirUsername`

Query params:

| Param | Description |
| :-- | :-- |
| `u` | integration account username |
| `t` | Connect token |
| `r` | `awardachievements` |
| `k` | player's RA username |

Multipart form-data payload:

| Field | Description | Example |
| :-- | :-- | :-- |
| `a` | CSV of achievement IDs, **no whitespace** | `147,141,145,142,146` |
| `h` | 1 hardcore / 0 softcore | `1` |
| `v` | `md5(csvIds + theirUsername + h)` — e.g. `md5("147,141,145,142,146TheirUsername1")` | `de4b6275cc8722872aa0fef6d4b30570` |

The hash pattern differs from the single-unlock one (no trailing repeat of the IDs).

```json
{
  "Success": true,
  "Score": 22890,
  "SoftcoreScore": 5,
  "ExistingIDs": [141, 147],
  "SuccessfulIDs": [142, 145, 146]
}
```

Already-unlocked IDs come back in `ExistingIDs` rather than as an error, so this call is **idempotent** — the correct primitive for a periodic resync.

## Implementation notes

- Award from your **server**, never from a client you don't control: the client would need the Connect token, and anyone holding it can grant achievements to anybody.
- Verification hashes are integrity checks against malformed calls, not authentication — the token is the credential.
- Keep an outbox/retry with backoff: a failed unlock must be retried (the batch call is idempotent, so a replay is safe).
- Achievement IDs must exist on the RA side first; there is no API to create achievements.

---

# Emulator-only functions

Not part of the standalone-integration contract above: these are what rcheevos
itself calls at game load. They are **not a public API**, carry no deprecation
promise, and can change without notice. They are documented here because they
are the *only* source for two things the Web API deliberately withholds, and
because a client that already holds a Connect token (e.g. one reading
`cheevos_token` from `retroarch.cfg`) can call them.

Rules for using them, all three learned the hard way:

1. **Treat a failure as "feature off", never as an error worth retrying hard.**
2. **Call once per game and cache on disk.** RetroArch makes the identical
   request at the same moment; you must not be heavier than the emulator.
3. **Send the token in the POST body, never the query string**, so no URL
   carrying a credential can reach a log.

## `r=patch` — the real achievement logic

`POST https://retroachievements.org/dorequest.php` with `u`, `t`, `r=patch`, `g=<gameId>`.

The public Web API **hashes** the two fields that matter: `API_GetGameExtended`
returns `"MemAddr": "84899845eff12e3cab0d9ba51a905ffc"` and
`"RichPresencePatch": "aeac4200f817f2ebc381675087f10aa4"` — MD5 digests, not
logic. That is a deliberate anti-cheat measure with no web-API workaround.
`r=patch` returns the real thing.

```jsonc
{ "Success": true,
  "PatchData": {
    "ID": 355, "Title": "…",
    "RichPresencePatch": "Format:…\nDisplay:…",
    "Achievements": [ { "ID": 312937, "Title": "…", "Description": "…",
                        "MemAddr": "Q:0xH00f000!=85_A:0xQ00f144_M:0xQ00f1a2=7",
                        "Points": 10, "BadgeName": "…", "Flags": 3,
                        "Type": "missable" } ],
    "Leaderboards": [ { "ID": 65174, "Title": "…", "Format": "TIME",
                        "Mem": "STA:…::CAN:…::SUB:…::VAL:M:0=0",
                        "LowerIsBetter": true, "Hidden": false } ] } }
```

`Flags`: `3` = official/core, `5` = unofficial/demoted (RetroArch does not track
these either). IDs at or above `100000000` are RA's own injected client-integrity
achievements ("Warning: Unknown Emulator") — never real achievements, always
filter them out.

## `r=achievementsets` — every set of a ROM hash, subsets included

`POST https://retroachievements.org/dorequest.php` with `u`, `t`,
`r=achievementsets`, `m=<RA hash of the content>`. The call rcheevos 1.22 makes
at game load; it returns the core set **and** every bonus set the hash runs,
each in `r=patch`'s achievement/leaderboard format. Observed 2026-10-18
(a downstream project, A Link to the Past, hash `608c22b8…`):

```jsonc
{ "Success": true, "GameId": 355, "Title": "…", "ConsoleId": 3,
  "ImageIconUrl": "…", "RichPresenceGameId": 355, "RichPresencePatch": "…",
  // Present when the User-Agent is not a recognised emulator; such a client
  // also gets the injected integrity achievement in the core set.
  "Warning": "The server does not recognize this client and will not allow hardcore unlocks. …",
  "Sets": [
    { "Title": null, "Type": "core", "AchievementSetId": 368, "GameId": 355,
      "ImageIconUrl": "…", "Achievements": [ /* 109 + 1 injected */ ], "Leaderboards": [ /* 16 */ ] },
    { "Title": "Low%", "Type": "bonus", "AchievementSetId": 38555, "GameId": 38565,
      "ImageIconUrl": "…", "Achievements": [ /* 14 */ ], "Leaderboards": [] } ] }
```

- Achievements here also carry `Author`, `Created`, `Modified`, `BadgeURL`,
  `BadgeLockedURL`, `Rarity`, `RarityHardcore` beside the `r=patch` fields.
- A bonus set's `GameId` is its **own web-API game id** (`ParentGameID` = the
  core's on `API_GetGameInfoAndUserProgress`): read its rows and unlock state
  there, and its counters via `API_GetUserProgress?i=355,38565` (CSV, one call).
  The web titles read "… [Subset - Low%]"; `Title` here is the short label.
- A subset's `DisplayOrder` on the web API was 0 for all 14 Low% achievements:
  order by id to keep the author's order.
- The hash is not on the web API side; RetroArch logs it:
  `Identified game: 355 "…" (<md5>)`. See the `retroarch` skill.

## `r=codenotes2` — names for RAM addresses

`POST` with `u`, `t`, `r=codenotes2`, `g=<gameId>`.

**This skill previously stated that RA publishes no naming for RAM addresses.
That was wrong.** Set developers annotate addresses in RA's Memory Inspector and
this endpoint returns those annotations. Verified 2026-08-20 against game 355
(A Link to the Past): HTTP 200, **736 notes**, covering 86 % of the addresses a
full compilation of that set's triggers reads.

```jsonc
{ "Success": true,
  "CodeNotes": [
    { "User": "TheMysticalOne", "Address": "0x000020",
      "Note": "Link's Y-coordinates [16-Bit]" },
    { "User": "suspect15", "Address": "0x00f343",
      "Note": "[8-bit] Bombs possessed" },
    { "User": "TheMysticalOne", "Address": "0x0000a0",
      "Note": "[16-bit] Room ID (not accurate on overworld)\r\n0x0000=Ganon's Boss Room\r\n…" }
  ] }
```

- `Address` is a **hex string** (`"0x00f343"`), not a number.
- `Note` is free text in whatever style the author chose. **The first line is the
  label; the rest is usually a value enumeration** far too long for a UI.
- Notes carry a redundant size marker in every shape — `[8-bit] X`,
  `X [16-Bit]`, `(32) X`, leading or trailing. Strip it; the expression you are
  labelling already knows its own width.
- A note describes the **whole byte**. A condition reading one bit of it must say
  which, or "Pendants obtained" gets attached to a claim about bit 2.
- Deleted notes come back as an empty `Note`; drop them rather than indexing an
  empty label.
- `r=codenotes` (without the `2`) does **not** exist: HTTP 422,
  `{"Success":false,"Code":"invalid_parameter","Error":"Unknown request: codenotes"}`.

Why it matters: without it, any UI showing *why* a trigger has not fired can only
print `0xH00f343>d0xH00f343`. With it, that reads `Bombs possessed ↑`. It is the
difference between a feature and a curiosity.
