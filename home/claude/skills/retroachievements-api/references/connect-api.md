# Connect API (`dorequest.php`) — standalone integrations

The **write** side of RetroAchievements. Used by emulators and by "standalone" integrations (a game or server that awards RA achievements natively, e.g. a private MMO server). Not needed for read-only projects.

- Single non-REST endpoint: `https://retroachievements.org/dorequest.php`
- The `r` query param selects the function (`login2`, `startsession`, `ping`, `awardachievement`, `awardachievements`).
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
