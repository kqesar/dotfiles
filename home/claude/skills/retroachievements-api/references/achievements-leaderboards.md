# Web API — achievements, leaderboards & site feeds

Base: `https://retroachievements.org/API/`. `y` required everywhere and omitted below.

---

## API_GetAchievementUnlocks — `?a=9&c=50&o=0`

Who unlocked a given achievement.

| Param | Req | Description |
| :-- | :-- | :-- |
| `a` | yes | achievement ID |
| `c` | | count, default **50**, max 500 |
| `o` | | offset, default 0 |

```json
{
  "Achievement": {
    "ID": 9,
    "Title": "That Was Easy",
    "Description": "Complete the first act in Green Hill Zone",
    "Points": 4,
    "TrueRatio": 4,
    "Author": "Scott",
    "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "DateCreated": "2012-11-02 00:03:12",
    "DateModified": "2023-08-08 00:36:59",
    "Type": "progression"
  },
  "Console": { "ID": 1, "Title": "Mega Drive" },
  "Game": { "ID": 1, "Title": "Sonic the Hedgehog" },
  "UnlocksCount": 24272,
  "UnlocksHardcoreCount": 10830,
  "TotalPlayers": 27079,
  "Unlocks": [
    {
      "User": "vipotaenko02",
      "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "RAPoints": 0,
      "RASoftcorePoints": 0,
      "DateAwarded": "2023-10-27T00:19:05.000000Z",
      "HardcoreMode": 0
    }
  ]
}
```

Rarity = `UnlocksCount / TotalPlayers` (or the hardcore variants). `Console`/`Game` use `Title`, not `Name`. Ordering is most-recent-first; paginate with `o` to walk history.

---

## API_GetAchievementOfTheWeek

No params beyond `y`. Current AotW event.

```json
{
  "Achievement": {
    "ID": 178634,
    "Title": "Saved Summer",
    "Description": "Defeat the Flower and let Summer Get Busy",
    "Points": 10,
    "TrueRatio": 11,
    "Type": null,
    "Author": "StingX2",
    "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "DateCreated": "2021-10-16",
    "DateModified": "2021-10-17"
  },
  "Console": { "ID": 3, "Title": "SNES" },
  "ForumTopic": { "ID": 19685 },
  "Game": { "ID": 2865, "Title": "~Hack~ Plumber For All Seasons, A" },
  "StartAt": "2023-10-23T00:00:00.000000Z",
  "TotalPlayers": 427,
  "Unlocks": [
    { "User": "Agnam", "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ", "RAPoints": 56120, "RASoftcorePoints": 1267, "DateAwarded": "2023-10-26T22:13:34.000000Z", "HardcoreMode": 1 }
  ],
  "UnlocksCount": 280,
  "UnlocksHardcoreCount": 268
}
```

`Unlocks` is unpaginated here — the payload grows with participation. Changes weekly; cache for the week, keyed on `StartAt`.

---

## API_GetGameLeaderboards — `?i=1&c=100&o=0`

All leaderboards of a game, each with its current #1.

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |
| `c` | | count, default 100, max 500 |
| `o` | | offset, default 0 |

```json
{
  "Count": 29,
  "Total": 29,
  "Results": [
    {
      "ID": 104370,
      "RankAsc": false,
      "Title": " South Island Conqueror",
      "Description": "Complete the game with the highest score possible",
      "Format": "VALUE",
      "Author": "Scott",
      "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZA",
      "TopEntry": {
        "User": "vani11a",
        "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
        "Score": "390490",
        "FormattedScore": "390,490"
      }
    }
  ]
}
```

`RankAsc: false` = higher score wins; `true` = lower wins (time attacks). `Format` drives `FormattedScore`: `VALUE`, `SCORE`, `TIME` (frames), `MILLISECS`, `SECS`, `MINUTES`, `FRAMES` and similar. **Always render `FormattedScore`** — reimplementing the formatter per format is a needless source of bugs. Note `TopEntry.Score` is a **string** here while `API_GetLeaderboardEntries` returns a number. Titles can carry leading whitespace (`" South Island Conqueror"`) — trim on display.

---

## API_GetLeaderboardEntries — `?i=104370&c=100&o=0`

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | **leaderboard** ID (not game ID) |
| `c` | | count, default 100, max 500 |
| `o` | | offset, default 0 |

```json
{
  "Count": 100,
  "Total": 1287,
  "Results": [
    {
      "Rank": 1,
      "User": "vani11a",
      "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "Score": 390490,
      "FormattedScore": "390,490",
      "DateSubmitted": "2024-07-25T15:51:00+00:00"
    }
  ]
}
```

Ties share a `Rank`, so ranks are not necessarily contiguous.

---

## API_GetRecentGameAwards — `?d=2024-01-01&c=25&o=0&k=mastered,completed`

Site-wide feed of mastery/beaten/completion awards.

| Param | Req | Description |
| :-- | :-- | :-- |
| `d` | | starting date `YYYY-MM-DD`, default now |
| `o` | | offset, default 0 |
| `c` | | count, default **25**, max **100** |
| `k` | | CSV of award kinds: `beaten-softcore`, `beaten-hardcore`, `completed`, `mastered` (default: all) |

```json
{
  "Count": 25,
  "Total": 172318,
  "Results": [
    {
      "User": "renanbrj",
      "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "AwardKind": "mastered",
      "AwardDate": "2022-01-01T23:48:04+00:00",
      "GameID": 14284,
      "GameTitle": "Batman Returns",
      "ConsoleID": 15,
      "ConsoleName": "Game Gear"
    }
  ]
}
```

`Total` is the count from `d` onward, so it is huge — never walk it fully. For a live feed, poll the first page at a sane interval and dedupe on `(ULID, GameID, AwardKind, AwardDate)`.

---

## API_GetTopTenUsers

No params beyond `y`. Top ten by **hardcore** points.

```json
[
  {
    "1": "MaxMilyin",
    "2": 399597,
    "3": 1599212,
    "4": "00003EMFWR7XB8SDPEHB3K56ZQ"
  }
]
```

Positional keys, not named fields: `"1"` username, `"2"` hardcore points, `"3"` RetroPoints (white points), `"4"` ULID. Map it to a real shape at the boundary — this format is a legacy wart and passing it around raw will haunt the codebase. There is no endpoint for ranks 11+.

---

## API_GetComments — `?i=1&t=1&c=100&o=0&sort=submitted`

Comment wall of a game, an achievement, or a user.

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game or achievement ID (`t`=1/2), or username/ULID (`t`=3) |
| `t` | sometimes | 1 game, 2 achievement, 3 user. Required for 1 and 2 |
| `c` | | count, default 100, max 500 |
| `o` | | offset, default 0 |
| `sort` | | `submitted` (ascending, default) or `-submitted` (descending) |

```json
{
  "Count": 4,
  "Total": 4,
  "Results": [
    {
      "User": "PlayTester",
      "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "Submitted": "2024-07-31T11:22:23.000000Z",
      "CommentText": "Comment 1"
    }
  ]
}
```

`CommentText` is **user-supplied**: escape it before rendering, never inject it as HTML. Users can disable their wall (`UserWallActive` on the profile).
