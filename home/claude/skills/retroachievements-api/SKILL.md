---
name: retroachievements-api
description: Complete offline reference for the RetroAchievements (RA) Web API and Connect API — every endpoint, its query params, its exact JSON response shape, and its gotchas. Use it INSTEAD of searching the web or reading api-docs.retroachievements.org whenever a task touches retroachievements.org, api-docs.retroachievements.org, `API_Get*.php`, `dorequest.php`, `@retroachievements/api`, RA game/achievement/leaderboard/hardcore/mastery/ULID/RA web API key concepts, or a codebase that already calls the RA API — in any language. STRICT SCOPE — do not load or apply this on projects unrelated to RetroAchievements; nothing here is a general HTTP/API convention.
---

# RetroAchievements API

Reference snapshot of the official docs (api-docs.retroachievements.org, RAWeb-driven), taken 2026-08-19 from the api-docs repo at commit 9d0aeb7 (2026-02-23). Every endpoint below is documented; use it directly instead of fetching docs.

## Scope guard

Apply this skill **only** when the work actually concerns RetroAchievements. If the project is unrelated, none of these conventions (the `y` key param, `c`/`o` pagination, `f=3/5` flags, the date-format quirks) transfer — they are RA-specific, not general API design.

## Two distinct APIs

| API | Base | Auth | Purpose |
| :-- | :-- | :-- | :-- |
| **Web API** (99% of use cases) | `https://retroachievements.org/API/API_<Name>.php` | `y` = web API key | Read-only JSON over games, users, achievements, leaderboards |
| **Connect API** | `https://retroachievements.org/dorequest.php?r=<function>` | `t` = Connect token (from `r=login2`) | Write side: start session, ping, unlock achievements. Standalone-integration only — see `references/connect-api.md` |

All Web API endpoints are `GET` and return JSON. There is no versioned path, no `Accept` negotiation, no body.

```
https://retroachievements.org/API/API_GetGame.php?i=1&y=<web_api_key>
```

**Key handling** (this is a secret — see `rules/deployment.md`): env var, never committed, never logged, never shipped to a browser bundle. A front-end that needs RA data proxies through your own back end; putting `y` in client JS publishes it.

### Errors and rate limiting

- Missing/invalid key → HTTP **401** with:
  ```json
  {"message":"Unauthenticated.","errors":[{"status":"401","code":"unauthorized","title":"Unauthenticated."}]}
  ```
  Success bodies never carry this envelope, so `"errors" in body` is a reliable failure check alongside the status code.
- Rate limiting is enabled site-wide but **no published limit, no documented `X-RateLimit-*` / `Retry-After` headers**. Treat 429/5xx as retryable with backoff, and design for caching rather than polling: game metadata is near-static, user progress changes slowly. On a 2 GB/1 vCore VPS (`rules/infra.md`), cache in Postgres/SQLite or an on-disk cache instead of hammering the API per page view.
- Bad IDs generally yield an empty array/object rather than a 404 — check for emptiness, don't assume an error status.

## Cross-cutting conventions

**`y`** — web API key, required on every Web API call.

**`u` (user target)** — accepts a **username or a ULID** (26-char Crockford base32, e.g. `00003EMFWR7XB8SDPEHB3K56ZQ`). Since 2025 users can rename themselves, so **usernames are not stable**: resolve once via `API_GetUserProfile`, persist the `ULID`, key your own tables on it. Storing usernames as a foreign key is the #1 modelling mistake on this API.

**Pagination — `c` (count) / `o` (offset)**, zero-based offset. Defaults and caps differ per endpoint; the ones that matter:

| Endpoint | default `c` | max `c` |
| :-- | :-- | :-- |
| `API_GetAchievementUnlocks` | 50 | 500 |
| `API_GetComments` | 100 | 500 |
| `API_GetGameLeaderboards`, `API_GetLeaderboardEntries`, `API_GetUserCompletionProgress`, `API_GetUserWantToPlayList`, `API_GetUsersIFollow`, `API_GetUsersFollowingMe` | 100 | 500 |
| `API_GetUserGameLeaderboards` | 200 | 500 |
| `API_GetUserRecentlyPlayedGames` | 10 | 50 |
| `API_GetRecentGameAwards` | 25 | 100 |
| `API_GetTicketData` (recent tickets / most-ticketed) | 10 | 100 |
| `API_GetGameList` | 0 = all | — |

Paginated endpoints return `{ "Count", "Total", "Results": [...] }`; older ones return a bare array. Never assume the wrapper — the table in the endpoint index says which.

**`f` (flags)** — achievement set filter: `3` = official/core (default), `5` = unofficial/demoted. Same meaning on `API_GetGameExtended`, `API_GetAchievementDistribution`, `API_GetTicketData?g=`. **Exception**: on `API_GetGameList`, `f=1` means "only games with achievements", and on `API_GetTicketData`, `f=1` selects the most-ticketed-games mode. Read `f` per endpoint.

**`h` (hardcore)** — hardcore filter, but the semantics shift: `1` = hardcore-only unlocks (`API_GetAchievementDistribution`), "prefer hardcore players" (`API_GetGameProgression`), "also return hashes" (`API_GetGameList` — unrelated meaning), unlock mode (Connect `awardachievement`).

**Hardcore vs softcore** — the core domain distinction. Hardcore = no savestates/cheats; it awards separate points and separate awards. Nearly every progress payload carries both (`TotalPoints` vs `TotalSoftcorePoints`, `NumAchieved` vs `NumAchievedHardcore`). Never sum them: hardcore unlocks are also counted in the softcore/total figures on most endpoints.

**Points vocabulary** — `Points` = achievement points; `TrueRatio`/`TotalTruePoints` = "RetroPoints"/white points, a rarity-weighted score. They are different scales; don't add them.

**Award kinds** — `"beaten-softcore"`, `"beaten-hardcore"`, `"completed"` (all achievements, softcore), `"mastered"` (all achievements, hardcore). Ranked in that order; `HighestAwardKind` gives the best one reached.

**Achievement `Type`** — `null` | `"progression"` | `"win_condition"` | `"missable"`. Beware: `API_GetGameExtended` and `API_GetGameInfoAndUserProgress` spell this key **lowercase `type`** inside the `Achievements` map, while every other endpoint uses `Type`.

**Dates — the biggest trap.** Two formats coexist, sometimes inside one response:
- `"2023-08-08 00:36:59"` — MySQL-style, **no timezone**, implicitly UTC. `new Date(...)` parses this as *local time* in some engines; parse explicitly.
- `"2024-07-25T15:51:00+00:00"` / `"2023-10-26T22:13:34.000000Z"` — ISO-8601, sometimes with 6-digit microseconds.
`API_GetAchievementsEarnedBetween` takes **epoch seconds** (`f`/`t`), while `API_GetAchievementsEarnedOnDay` takes `YYYY-MM-DD`.

**Types are inconsistent.** Booleans arrive as `0`/`1`, `"0"`/`"1"`, and real `true`/`false` depending on the endpoint (`"HardcoreMode": "0"`, `"IsAwarded": "1"`, `"Active": true`, `"Untracked": 0`). Numbers arrive as strings (`"PctWon": "1.0000"`, `"Score": "390490"` in `TopEntry` but a number in leaderboard entries). Percentages arrive as strings with a `%` (`"UserCompletion": "100.00%"`).
→ In TS, **validate at the boundary with Zod and coerce there** (`rules/js-ts.md`): the RA API is a third-party surface that has changed field types before, and a `as GameResponse` cast proves nothing at runtime. One `safeParse` per response, at the fetch layer, with `z.coerce.number()` / a `0|1|"0"|"1"` → boolean transform; downstream code then works on clean types. Skip validation and the bug shows up as `"0"` being truthy, i.e. every softcore unlock counted as hardcore.

**Images** — responses return paths (`/Images/067895.png`, `/Badge/250336.png`, `/UserPic/Name.png`). Prefix with `https://media.retroachievements.org` (the CDN; `https://retroachievements.org` also serves them). `IconURL` on `API_GetConsoleIDs` is already absolute (`static.retroachievements.org`).

**Deprecated / legacy** — `IsFinal` always returns `false` (game payloads); `API_GetUserCompletedGames` is legacy, prefer `API_GetUserCompletionProgress`.

**Client libraries** — official: `@retroachievements/api` (JS/TS, camelCases every field) and `api-kotlin`. In JS/TS install with **pnpm** (`rules/js-ts.md`). The library is a thin wrapper; a hand-rolled `fetch` + Zod layer is a legitimate choice and is what the field tables below describe (**PascalCase, raw HTTP names**). Don't mix the two naming conventions in one codebase.

## Endpoint index

Every documented endpoint. `→ file` points at the reference holding the full response JSON.

### Users — `references/users.md`

| Endpoint | Params | Returns |
| :-- | :-- | :-- |
| `API_GetUserProfile` | `u`* | object — identity, points, `ULID`, `LastGameID`, motto |
| `API_GetUserSummary` | `u`, `g` (recent games, default 0), `a` (recent achievements, default 10) | object — profile + `RecentlyPlayed` + `Awarded` map + `RecentAchievements` map + `LastGame` + `Rank`. Recent achievements come *from* the recent games, so `g=0` yields none |
| `API_GetUserPoints` | `u` | `{Points, SoftcorePoints}` |
| `API_GetUserAwards` | `u` | object — award counters + `VisibleUserAwards[]` |
| `API_GetUserCompletionProgress` | `u`, `c`, `o` | wrapped — per-game award progress. **Preferred** progress endpoint |
| `API_GetUserCompletedGames` | `u` | array — legacy; two rows per game (softcore + hardcore) |
| `API_GetUserProgress` | `u`, `i`* (CSV of game IDs) | map gameID → counters. Best bulk-progress call |
| `API_GetUserRecentAchievements` | `u`, `m` (minutes back, default 60) | array of unlocks |
| `API_GetAchievementsEarnedOnDay` | `u`, `d`* (`YYYY-MM-DD`) | array of unlocks |
| `API_GetAchievementsEarnedBetween` | `u`, `f`*, `t`* (epoch seconds) | array of unlocks (+ `CumulScore`) |
| `API_GetUserRecentlyPlayedGames` | `u`, `c`, `o` | array — game + per-game progress |
| `API_GetUserGameRankAndScore` | `u`, `g`* | array (empty if no progress) — rank on that game |
| `API_GetUserGameLeaderboards` | `i`*, `u`*, `c`, `o` | wrapped — leaderboards with the user's own entry |
| `API_GetUserWantToPlayList` | `u`, `c`, `o` | wrapped — only visible for yourself or mutual follows |
| `API_GetUserSetRequests` | `u`, `t` (0 active / 1 all) | `{RequestedSets[], TotalRequests, PointsForNext}` |
| `API_GetUserClaims` | `u` | array of that user's set claims |
| `API_GetUsersIFollow` | `c`, `o` | wrapped — **caller's** following list (key owner, no `u`) |
| `API_GetUsersFollowingMe` | `c`, `o` | wrapped — caller's followers |

### Games & systems — `references/games.md`

| Endpoint | Params | Returns |
| :-- | :-- | :-- |
| `API_GetGame` | `i`* | object — basic metadata (no achievements) |
| `API_GetGameExtended` | `i`*, `f` (3/5) | object — full metadata + `Achievements` **map keyed by achievement ID** + `Claims` |
| `API_GetGameInfoAndUserProgress` | `u`*, `g`*, `a` (1 = include award metadata) | GameExtended + per-achievement `DateEarned`/`DateEarnedHardcore` + completion + `HighestAwardKind` |
| `API_GetGameHashes` | `i`* | `{Results:[{MD5, Name, Labels[], PatchUrl}]}` |
| `API_GetGameList` | `i`* (system), `f` (1 = only with achievements), `h` (1 = include hashes), `o`, `c` | array — full game list for a system |
| `API_GetConsoleIDs` | `a` (1 = active only), `g` (1 = real gaming systems only, excludes Hubs/Events) | array `{ID, Name, IconURL, Active, IsGameSystem}` |
| `API_GetGameRankAndScore` | `g`*, `t` (1 = latest masters, 0 = high scores) | array — top players for a game |
| `API_GetGameProgression` | `i`*, `h` | median time-to-beat/complete/master + per-achievement median unlock times |
| `API_GetAchievementCount` | `i`* | `{GameID, AchievementIDs[]}` — cheap revision detector |
| `API_GetAchievementDistribution` | `i`*, `h`, `f` | map "N achievements earned" → player count |

### Achievements, leaderboards, site feeds — `references/achievements-leaderboards.md`

| Endpoint | Params | Returns |
| :-- | :-- | :-- |
| `API_GetAchievementUnlocks` | `a`*, `c`, `o` | achievement + console + game + `Unlocks[]` |
| `API_GetAchievementOfTheWeek` | — | current AotW: achievement, game, console, `StartAt`, `Unlocks[]` |
| `API_GetGameLeaderboards` | `i`*, `c`, `o` | wrapped — leaderboards of a game + `TopEntry` |
| `API_GetLeaderboardEntries` | `i`* (leaderboard ID), `c`, `o` | wrapped — ranked entries |
| `API_GetRecentGameAwards` | `d` (`YYYY-MM-DD` start), `o`, `c`, `k` (CSV of award kinds) | wrapped — site-wide award feed |
| `API_GetTopTenUsers` | — | array of **positional objects** keyed `"1".."4"` — see the file |
| `API_GetComments` | `i`*, `t` (1 game / 2 achievement / 3 user), `c`, `o`, `sort` (`submitted` / `-submitted`) | wrapped — comment wall |

### Tickets & claims — `references/tickets-claims.md`

| Endpoint | Params | Mode |
| :-- | :-- | :-- |
| `API_GetTicketData` | `i`* (ticket ID) | one ticket, full metadata |
| `API_GetTicketData` | `a`* (achievement ID) | open-ticket stats for an achievement |
| `API_GetTicketData` | `g`*, `f` (5 = unofficial), `d` (1 = deep `Tickets[]`) | open-ticket stats for a game |
| `API_GetTicketData` | `u` | ticket stats for a developer |
| `API_GetTicketData` | `c`, `o` (no other selector) | most recent tickets site-wide |
| `API_GetTicketData` | `f=1`*, `c`, `o` | most-ticketed games |
| `API_GetActiveClaims` | — | all active set claims (1000 max) |
| `API_GetClaims` | `k` (1 completed / 2 dropped / 3 expired, default 1) | inactive claims (1000 max) |

`*` = required. `y` required everywhere and omitted from the tables.

## Task → endpoint

- **A user's overall progress on many games** → `API_GetUserCompletionProgress` (paginated, one call per 100 games), not N× `API_GetGameInfoAndUserProgress`.
- **Progress on a known short list of games** → `API_GetUserProgress?i=1,2,3` — one call, counters only.
- **Full achievement detail + who unlocked what, for one game/user** → `API_GetGameInfoAndUserProgress`.
- **"Has this set been revised?"** → poll `API_GetAchievementCount` (tiny payload) or compare `Updated` from `API_GetGameExtended`; only refetch the full set when it moves.
- **Building a local mirror of a system's catalogue** → `API_GetGameList?i=<system>&f=1`, then `API_GetGameExtended` per game, throttled and cached. Fetch `API_GetConsoleIDs?g=1&a=1` first.
- **Matching a local ROM to an RA game** → hash the file, look it up in `API_GetGameHashes` (RA uses its own MD5 scheme per console — rcheevos is authoritative for how the hash is computed for non-trivial systems).
- **Live "what's happening" feed** → `API_GetRecentGameAwards` (+ `API_GetAchievementOfTheWeek`), respecting the rate limit.
- **Awarding achievements from your own game/server** → Connect API, `references/connect-api.md`.

## Known limits

- No write access on the Web API. No search endpoint (no "find game by name") — mirror `API_GetGameList` locally and search your own copy.
- No "all users" or "global leaderboard beyond top ten" endpoint.
- Missing data can be requested from the RA team: https://github.com/RetroAchievements/RAWeb/discussions/2081
- Breaking changes do happen; they land in RAWeb releases. If a response here disagrees with reality, reality wins — fix the reference file and say so.
