# Web API — user endpoints

Base: `https://retroachievements.org/API/`. `y` (web API key) required on every call and omitted below.
`u` accepts a username **or a ULID**; persist the ULID (usernames are mutable since 2025).

---

## API_GetUserProfile — `?u=MaxMilyin`

Minimal identity + points. The cheapest way to turn a username into a stable `ULID`.

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |

```json
{
  "User": "MaxMilyin",
  "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
  "UserPic": "/UserPic/MaxMilyin.png",
  "MemberSince": "2016-01-02 00:43:04",
  "RichPresenceMsg": "Playing ~Hack~ 11th Annual Vanilla Level Design Contest, The",
  "LastGameID": 19504,
  "ContribCount": 0,
  "ContribYield": 0,
  "TotalPoints": 399597,
  "TotalSoftcorePoints": 0,
  "TotalTruePoints": 1599212,
  "Permissions": 1,
  "Untracked": 0,
  "ID": 16446,
  "UserWallActive": 1,
  "Motto": "Join me on Twitch! GameSquadSquad for live RA"
}
```

`ContribCount`/`ContribYield` = achievements this user authored that others unlocked, and the points those yielded (dev stats). `Untracked: 1` = excluded from rankings (cheating flag). `Permissions`: 1 = registered; higher = jr dev / dev / admin. Motto max length 50 chars — the Connect API account-linking flow uses it.

---

## API_GetUserSummary — `?u=xelnia&g=1&a=2`

Profile + recent activity in one call. Heavy; don't call it in a loop.

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `g` | | number of recent games (default **0**) |
| `a` | | number of recent achievements (default 10) |

Recent achievements are pulled **from the recent games**, so `g=0` returns none, and `g=1&a=10` on a game where the user earned 8 returns 8.

```json
{
  "User": "xelnia",
  "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
  "MemberSince": "2021-12-20 03:13:20",
  "LastActivity": { "ID": 0, "timestamp": null, "lastupdate": null, "activitytype": null, "User": "xelnia", "data": null, "data2": null },
  "RichPresenceMsg": "L=08-1 | 1 lives | 189300 points",
  "RichPresenceMsgDate": "2025-11-19 12:05:04",
  "LastGameID": 15758,
  "ContribCount": 0,
  "ContribYield": 0,
  "TotalPoints": 8317,
  "TotalSoftcorePoints": 0,
  "TotalTruePoints": 26760,
  "Permissions": 1,
  "Untracked": 0,
  "ID": 224958,
  "UserWallActive": 1,
  "Motto": "",
  "Rank": 4616,
  "RecentlyPlayedCount": 1,
  "RecentlyPlayed": [
    {
      "GameID": 15758, "ConsoleID": 27, "ConsoleName": "Arcade", "Title": "Crazy Kong",
      "ImageIcon": "/Images/068578.png", "ImageTitle": "/Images/068579.png",
      "ImageIngame": "/Images/068580.png", "ImageBoxArt": "/Images/068205.png",
      "LastPlayed": "2023-03-09 08:20:34", "AchievementsTotal": 43
    }
  ],
  "Awarded": {
    "15758": {
      "NumPossibleAchievements": 43, "PossibleScore": 615,
      "NumAchieved": 41, "ScoreAchieved": 490,
      "NumAchievedHardcore": 41, "ScoreAchievedHardcore": 490
    }
  },
  "RecentAchievements": {
    "15758": {
      "293505": {
        "ID": 293505, "GameID": 15758, "GameTitle": "Crazy Kong",
        "Title": "Prodigy of the Arcade", "Description": "Score 200,000 points",
        "Points": 25, "Type": null, "BadgeName": "325551",
        "IsAwarded": "1", "DateAwarded": "2023-03-09 08:20:34", "HardcoreAchieved": 1
      }
    }
  },
  "LastGame": {
    "ID": 15758, "Title": "Crazy Kong", "ConsoleID": 27, "ConsoleName": "Arcade",
    "ForumTopicID": 20415, "Flags": 0,
    "ImageIcon": "/Images/068578.png", "ImageTitle": "/Images/068579.png",
    "ImageIngame": "/Images/068580.png", "ImageBoxArt": "/Images/068205.png",
    "Publisher": "Falcon", "Developer": "Falcon", "Genre": "2D Platforming, Arcade",
    "Released": "1981-01-01", "ReleasedAtGranularity": "year", "IsFinal": 0
  },
  "UserPic": "/UserPic/xelnia.png",
  "TotalRanked": 45654,
  "Status": "Offline"
}
```

`Awarded` and `RecentAchievements` are **maps keyed by game ID (string)**, and `RecentAchievements[gameId]` is itself a map keyed by achievement ID. `IsAwarded` is the string `"1"`. `Rank` is the hardcore rank, `TotalRanked` the number of ranked users.

---

## API_GetUserPoints — `?u=Hexadigital`

```json
{ "Points": 31299, "SoftcorePoints": 24264 }
```

`Points` = hardcore points. Cheapest possible user call.

---

## API_GetUserAwards — `?u=MaxMilyin`

`AwardType` values: `"Mastery/Completion"`, `"Game Beaten"`, `"Achievement Unlocks Yield"`, `"Achievement Points Yield"`, `"Patreon Supporter"`, `"Certified Legend"`.

```json
{
  "TotalAwardsCount": 1613,
  "HiddenAwardsCount": 0,
  "MasteryAwardsCount": 805,
  "CompletionAwardsCount": 0,
  "BeatenHardcoreAwardsCount": 807,
  "BeatenSoftcoreAwardsCount": 0,
  "EventAwardsCount": 2,
  "SiteAwardsCount": 0,
  "VisibleUserAwards": [
    {
      "AwardedAt": "2016-01-02T05:53:52+00:00",
      "AwardType": "Game Beaten",
      "AwardData": 1448,
      "AwardDataExtra": 1,
      "DisplayOrder": 0,
      "Title": "Mega Man",
      "ConsoleID": 7,
      "ConsoleName": "NES",
      "Flags": 0,
      "ImageIcon": "/Images/024519.png"
    }
  ]
}
```

`AwardData` = the game ID for game awards. `AwardDataExtra` = 1 hardcore / 0 softcore. Users can hide awards → `HiddenAwardsCount`; `VisibleUserAwards` only holds the visible ones.

---

## API_GetUserCompletionProgress — `?u=MaxMilyin&c=100&o=0`

**The endpoint to use for "all games a user has touched"**. Paginated, one row per game (not per mode).

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `c` | | count, default 100, max 500 |
| `o` | | offset, default 0 |

```json
{
  "Count": 100,
  "Total": 1287,
  "Results": [
    {
      "GameID": 20246,
      "Title": "~Hack~ Knuckles the Echidna in Sonic the Hedgehog",
      "ImageIcon": "/Images/074560.png",
      "ConsoleID": 1,
      "ConsoleName": "Mega Drive / Genesis",
      "MaxPossible": 0,
      "NumAwarded": 0,
      "NumAwardedHardcore": 0,
      "MostRecentAwardedDate": "2023-10-27T02:52:34+00:00",
      "HighestAwardKind": "beaten-hardcore",
      "HighestAwardDate": "2023-10-27T02:52:34+00:00"
    }
  ]
}
```

`HighestAwardKind` ∈ `null | "beaten-softcore" | "beaten-hardcore" | "completed" | "mastered"`.

---

## API_GetUserCompletedGames — `?u=MaxMilyin`  *(legacy)*

Legacy: prefer `API_GetUserCompletionProgress`. Returns **two rows per game** (softcore + hardcore), distinguished by `HardcoreMode`.

```json
[
  {
    "GameID": 19921,
    "Title": "Mega Man: Powered Up [Subset - 468 Stages]",
    "ImageIcon": "/Images/073205.png",
    "ConsoleID": 41,
    "ConsoleName": "PlayStation Portable",
    "MaxPossible": 481,
    "NumAwarded": 481,
    "PctWon": "1.0000",
    "HardcoreMode": "0"
  }
]
```

`PctWon` and `HardcoreMode` are **strings**. Not paginated.

---

## API_GetUserProgress — `?u=MaxMilyin&i=1,2,3`

Bulk counters for a known list of game IDs. One request, no pagination — best call when you already know which games you care about.

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `i` | yes | comma-separated game IDs |

```json
{
  "1": { "NumPossibleAchievements": 23, "PossibleScore": 251, "NumAchieved": 23, "ScoreAchieved": 251, "NumAchievedHardcore": 23, "ScoreAchievedHardcore": 251 },
  "2": { "NumPossibleAchievements": 22, "PossibleScore": 320, "NumAchieved": 22, "ScoreAchieved": 320, "NumAchievedHardcore": 22, "ScoreAchievedHardcore": 320 }
}
```

Map keyed by game ID as a **string**. In Zod: `z.record(z.string(), progressSchema)`.

---

## API_GetUserRecentAchievements — `?u=Scott&m=60`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `m` | | minutes to look back, default 60 |

```json
[
  {
    "Date": "2023-12-27 16:04:50",
    "HardcoreMode": 1,
    "AchievementID": 98012,
    "Title": "Beginner I",
    "Description": "Clear stages 01 - 05 in Quest.",
    "BadgeName": "108302",
    "Points": 5,
    "TrueRatio": 25,
    "Type": null,
    "Author": "jos",
    "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "GameTitle": "Pokemon Pinball mini",
    "GameIcon": "/Images/028399.png",
    "GameID": 14715,
    "ConsoleName": "Pokemon Mini",
    "BadgeURL": "/Badge/108302.png",
    "GameURL": "/game/14715"
  }
]
```

Polling this per user is the usual "new unlocks" mechanism; keep `m` slightly larger than your poll interval and dedupe on `(AchievementID, HardcoreMode, Date)`.

---

## API_GetAchievementsEarnedOnDay — `?u=MaxMilyin&d=2022-10-14`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `d` | yes | `YYYY-MM-DD` |

Same row shape as `API_GetUserRecentAchievements`, plus `CumulScore` (running point total across the day):

```json
[
  {
    "Date": "2022-10-14 00:43:58", "HardcoreMode": 1, "AchievementID": 250780,
    "Title": "Play With Yourself", "Description": "Completed Rank F in the Monster Arena",
    "BadgeName": "277506", "Points": 5, "Type": null,
    "Author": "TheMysticalOne", "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "GameTitle": "Dragon Quest VIII: Journey of the Cursed King", "GameIcon": "/Images/038649.png",
    "GameID": 2721, "ConsoleName": "PlayStation 2", "CumulScore": 5,
    "BadgeURL": "/Badge/277506.png", "GameURL": "/game/2721"
  }
]
```

---

## API_GetAchievementsEarnedBetween — `?u=Jamiras&f=1641054603&t=1641659403`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `f` | yes | **epoch seconds**, range start |
| `t` | yes | **epoch seconds**, range end |

Note `f`/`t` here are timestamps, not the usual "flags" meaning. Row shape identical to the on-day endpoint (includes `TrueRatio` and `CumulScore`):

```json
[
  {
    "Date": "2022-01-01 22:41:48", "HardcoreMode": 1, "AchievementID": 175333,
    "Title": "Solo Adventurer - Golden Beetles",
    "Description": "Solo defeat Golden Beetles at 2nd block (normal or above)",
    "BadgeName": "228985", "Points": 10, "TrueRatio": 25, "Type": "missable",
    "Author": "Altomar", "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "GameTitle": "Persona 3 Portable", "GameIcon": "/Images/065205.png", "GameID": 3164,
    "ConsoleName": "PlayStation Portable", "CumulScore": 10,
    "BadgeURL": "/Badge/228985.png", "GameURL": "/game/3164"
  }
]
```

Use this (not repeated on-day calls) to backfill history.

---

## API_GetUserRecentlyPlayedGames — `?u=MaxMilyin&c=10&o=0`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `c` | | count, default **10**, max **50** |
| `o` | | offset, default 0 |

```json
[
  {
    "GameID": 11332, "ConsoleID": 12, "ConsoleName": "PlayStation",
    "Title": "Final Fantasy Origins",
    "ImageIcon": "/Images/060249.png", "ImageTitle": "/Images/026707.png",
    "ImageIngame": "/Images/026708.png", "ImageBoxArt": "/Images/046257.png",
    "LastPlayed": "2023-10-27 00:30:04",
    "AchievementsTotal": 119,
    "NumPossibleAchievements": 119, "PossibleScore": 945,
    "NumAchieved": 38, "ScoreAchieved": 382,
    "NumAchievedHardcore": 38, "ScoreAchievedHardcore": 382
  }
]
```

Bare array (no `Count`/`Total` wrapper) despite being paginated.

---

## API_GetUserGameRankAndScore — `?u=WCopeland&g=14402`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `g` | yes | game ID |

**Empty array if the user has no progress on that game** — not a 404.

```json
[
  { "User": "WCopeland", "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ", "UserRank": 9, "TotalScore": 199, "LastAward": "2023-06-07 14:44:00" }
]
```

---

## API_GetUserGameLeaderboards — `?i=1&u=zuliman92&c=200&o=0`

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |
| `u` | yes | username or ULID |
| `c` | | count, default **200**, max 500 |
| `o` | | offset, default 0 |

```json
{
  "Count": 10,
  "Total": 64,
  "Results": [
    {
      "ID": 19062,
      "RankAsc": true,
      "Title": "New Zealand One",
      "Description": "Complete New Zealand S1 in least time",
      "Format": "MILLISECS",
      "UserEntry": {
        "User": "zuliman92",
        "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
        "Score": 12620,
        "FormattedScore": "2:06.20",
        "Rank": 2,
        "DateUpdated": "2024-12-12T16:40:59+00:00"
      }
    }
  ]
}
```

`RankAsc: true` = lower score is better. Always display `FormattedScore`; `Score` is the raw value in the leaderboard's `Format` unit.

---

## API_GetUserWantToPlayList — `?u=MaxMilyin&c=100&o=0`

Only returns data if the target is **you**, or if you and the target **follow each other**. Otherwise expect an empty/blocked result.

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `c` | | count, default 100, max 500 |
| `o` | | offset, default 0 |

```json
{
  "Count": 100,
  "Total": 1287,
  "Results": [
    {
      "ID": 20246,
      "Title": "~Hack~ Knuckles the Echidna in Sonic the Hedgehog",
      "ImageIcon": "/Images/074560.png",
      "ConsoleID": 1,
      "ConsoleName": "Genesis/Mega Drive",
      "PointsTotal": 1500,
      "AchievementsPublished": 50
    }
  ]
}
```

---

## API_GetUserSetRequests — `?u=MaxMilyin&t=0`

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `t` | | 0 = active requests (default), 1 = all requests |

```json
{
  "RequestedSets": [
    { "GameID": 8149, "Title": "Jurassic Park Institute Tour: Dinosaur Rescue", "ConsoleID": 5, "ConsoleName": "Game Boy Advance", "ImageIcon": "/Images/000001.png" }
  ],
  "TotalRequests": 5,
  "PointsForNext": 5000
}
```

Set requests are the community mechanism for asking devs to build an achievement set. `PointsForNext` = points the user must still earn to unlock another request slot.

---

## API_GetUserClaims — `?u=Jamiras`

All set-development claims made by a user, lifetime. Same row shape as `API_GetActiveClaims` — see `tickets-claims.md` for the field semantics (`ClaimType`, `SetType`, `Status`, `MinutesLeft`).

```json
[
  {
    "ID": 11161, "User": "Jamiras", "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "GameID": 18644, "GameTitle": "~Unlicensed~ Hi-Leg Fantasy", "GameIcon": "/Images/083201.png",
    "ConsoleID": 76, "ConsoleName": "PC Engine CD",
    "ClaimType": 0, "SetType": 0, "Status": 0, "Extension": 0, "Special": 0,
    "Created": "2023-10-16 02:25:34", "DoneTime": "2024-01-16 02:25:34",
    "Updated": "2023-10-16 02:25:34", "UserIsJrDev": 0, "MinutesLeft": -58300
  }
]
```

---

## API_GetUsersIFollow / API_GetUsersFollowingMe — `?c=100&o=0`

**No `u` param** — these are always about the account that owns the API key.

| Param | Req | Description |
| :-- | :-- | :-- |
| `c` | | count, default 100, max 500 |
| `o` | | offset, default 0 |

```json
{
  "Count": 20,
  "Total": 120,
  "Results": [
    { "User": "zuliman92", "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ", "Points": 1882, "PointsSoftcore": 258, "AmIFollowing": true }
  ]
}
```

`API_GetUsersIFollow` returns `IsFollowingMe` instead of `AmIFollowing` — same position, different key. Compare both to find mutual follows (needed for `API_GetUserWantToPlayList`).
