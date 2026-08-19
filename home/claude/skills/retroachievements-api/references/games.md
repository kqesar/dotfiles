# Web API — game & system endpoints

Base: `https://retroachievements.org/API/`. `y` required everywhere and omitted below.

Game metadata is near-static — cache it aggressively and refresh on `Updated` / achievement-count change rather than on every request.

---

## API_GetGame — `?i=1`

Basic metadata, **no achievements**. Note the duplicated legacy fields (`Title`/`GameTitle`, `ConsoleName`/`Console`, `ImageIcon`/`GameIcon`).

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |

```json
{
  "Title": "Sonic the Hedgehog",
  "GameTitle": "Sonic the Hedgehog",
  "ConsoleID": 1,
  "ConsoleName": "Mega Drive",
  "Console": "Mega Drive",
  "ForumTopicID": 112,
  "Flags": 0,
  "GameIcon": "/Images/067895.png",
  "ImageIcon": "/Images/067895.png",
  "ImageTitle": "/Images/054993.png",
  "ImageIngame": "/Images/000010.png",
  "ImageBoxArt": "/Images/051872.png",
  "Publisher": "",
  "Developer": "",
  "Genre": "",
  "Released": "1992-06-02 00:00:00",
  "ReleasedAtGranularity": "day"
}
```

`ReleasedAtGranularity` ∈ `"day" | "month" | "year"` — respect it when formatting, `Released` is padded to a full timestamp regardless of how precise the real date is. `Publisher`/`Developer`/`Genre` are frequently empty strings, not null.

---

## API_GetGameExtended — `?i=1&f=3`

Full metadata + the achievement set. The main "everything about this game" call.

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |
| `f` | | 3 = official (default), 5 = unofficial/demoted achievements |

```json
{
  "ID": 1,
  "Title": "Sonic the Hedgehog",
  "ConsoleID": 1,
  "ForumTopicID": 112,
  "Flags": null,
  "ImageIcon": "/Images/067895.png",
  "ImageTitle": "/Images/054993.png",
  "ImageIngame": "/Images/000010.png",
  "ImageBoxArt": "/Images/051872.png",
  "Publisher": "",
  "Developer": "",
  "Genre": "",
  "Released": "1992-06-02",
  "ReleasedAtGranularity": "day",
  "IsFinal": false,
  "RichPresencePatch": "cce60593880d25c97797446ed33eaffb",
  "GuideURL": null,
  "Updated": "2023-12-27T13:51:14.000000Z",
  "ConsoleName": "Mega Drive",
  "ParentGameID": null,
  "NumDistinctPlayers": 27080,
  "NumAchievements": 23,
  "Achievements": {
    "9": {
      "ID": 9,
      "NumAwarded": 24273,
      "NumAwardedHardcore": 10831,
      "Title": "That Was Easy",
      "Description": "Complete the first act in Green Hill Zone",
      "Points": 3,
      "TrueRatio": 3,
      "Author": "Scott",
      "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "DateModified": "2023-08-08 00:36:59",
      "DateCreated": "2012-11-02 00:03:12",
      "BadgeName": "250336",
      "DisplayOrder": 1,
      "MemAddr": "22c9d5e2cd7571df18a1a1b43dfe1fea",
      "type": "progression"
    }
  },
  "Claims": [],
  "NumDistinctPlayersCasual": 27080,
  "NumDistinctPlayersHardcore": 27080
}
```

Key points:
- `Achievements` is an **object keyed by achievement ID as a string**, not an array. Sort by `DisplayOrder` for site-like ordering (`Object.values(...).sort((a,b) => a.DisplayOrder - b.DisplayOrder)`).
- The achievement type key is **lowercase `type`** here (and in `API_GetGameInfoAndUserProgress`), unlike `Type` everywhere else. Values: `null | "progression" | "win_condition" | "missable"`. Progression + win_condition define the "beaten" award.
- `MemAddr` = the achievement's memory-inspection logic, hashed/serialised. Useless outside emulator work.
- `RichPresencePatch` = the game's rich-presence script (hashed here). `ParentGameID` is set for subsets/bonus sets — a subset is a separate game ID pointing at its parent.
- `IsFinal` is deprecated and always `false`. `Flags` is `null` here but `0` in `API_GetGame`.
- `Updated` is the cheap cache key for "did anything change".
- Badge image: `https://media.retroachievements.org/Badge/{BadgeName}.png`; locked variant is `{BadgeName}_lock.png`.

---

## API_GetGameInfoAndUserProgress — `?g=14402&u=MaxMilyin&a=1`

`API_GetGameExtended` + one user's unlock state. The call behind any "game page for this user" screen.

| Param | Req | Description |
| :-- | :-- | :-- |
| `u` | yes | username or ULID |
| `g` | yes | game ID |
| `a` | | 1 = include user award metadata (`HighestAwardKind`/`HighestAwardDate`), default 0 |

Same body as `API_GetGameExtended` (minus `Claims`, plus progress). Each achievement gains `DateEarned` / `DateEarnedHardcore`, **present only if unlocked**:

```json
{
  "ID": 1,
  "Title": "Sonic the Hedgehog",
  "ConsoleID": 1,
  "ConsoleName": "Mega Drive",
  "ForumTopicID": 112,
  "Flags": null,
  "ImageIcon": "/Images/067895.png",
  "ImageTitle": "/Images/054993.png",
  "ImageIngame": "/Images/000010.png",
  "ImageBoxArt": "/Images/051872.png",
  "Publisher": "", "Developer": "", "Genre": "",
  "Released": "1992-06-02 00:00:00",
  "ReleasedAtGranularity": "day",
  "IsFinal": false,
  "RichPresencePatch": "cce60593880d25c97797446ed33eaffb",
  "GuideURL": null,
  "ParentGameID": null,
  "NumDistinctPlayers": 27080,
  "NumAchievements": 23,
  "Achievements": {
    "9": {
      "ID": 9, "NumAwarded": 24273, "NumAwardedHardcore": 10831,
      "Title": "That Was Easy", "Description": "Complete the first act in Green Hill Zone",
      "Points": 3, "TrueRatio": 3, "Author": "Scott", "AuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "DateModified": "2023-08-08 00:36:59", "DateCreated": "2012-11-02 00:03:12",
      "BadgeName": "250336", "DisplayOrder": 1, "MemAddr": "22c9d5e2cd7571df18a1a1b43dfe1fea",
      "type": "progression",
      "DateEarnedHardcore": "2016-03-12 17:47:29",
      "DateEarned": "2016-03-12 17:47:29"
    }
  },
  "NumAwardedToUser": 23,
  "NumAwardedToUserHardcore": 23,
  "NumDistinctPlayersCasual": 27080,
  "NumDistinctPlayersHardcore": 27080,
  "UserCompletion": "100.00%",
  "UserCompletionHardcore": "100.00%",
  "UserTotalPlaytime": 60,
  "HighestAwardKind": "mastered",
  "HighestAwardDate": "2024-04-23T21:28:49+00:00"
}
```

`UserCompletion` / `UserCompletionHardcore` are **strings ending in `%`** — parse, don't display raw if you need arithmetic. `UserTotalPlaytime` is in **minutes**. A hardcore unlock always implies the softcore one, so `DateEarned` is set whenever `DateEarnedHardcore` is.

Don't loop this over a user's whole library — use `API_GetUserCompletionProgress` or `API_GetUserProgress` instead.

---

## API_GetGameHashes — `?i=1`

Supported ROM files for a game.

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |

```json
{
  "Results": [
    {
      "MD5": "1b1d9ac862c387367e904036114c4825",
      "Name": "Sonic The Hedgehog (USA, Europe) (Ru) (NewGame).md",
      "Labels": ["nointro", "rapatches"],
      "PatchUrl": "https://github.com/RetroAchievements/RAPatches/raw/main/MD/Translation/Russian/1-Sonic1-Russian.zip"
    },
    {
      "MD5": "1bc674be034e43c96b86487ac69d9293",
      "Name": "Sonic The Hedgehog (USA, Europe).md",
      "Labels": ["nointro"],
      "PatchUrl": null
    }
  ]
}
```

The MD5 is RA's own hash, **not always a plain file MD5** — many consoles hash only part of the ROM (header stripping, track selection for disc images). `rcheevos` is the authoritative implementation; reimplementing it per system is the hard part of any ROM-matching feature. `Labels` mark the source (`nointro`, `rapatches`, …), `PatchUrl` points at the hack/translation patch when the entry is a patched ROM.

---

## API_GetGameList — `?i=1&f=1&h=1&o=0&c=0`

Whole catalogue for one system. The backbone of any local mirror.

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | system/console ID |
| `f` | | **1 = only games that have achievements** (not the flags meaning), default 0 |
| `h` | | 1 = also return the `Hashes` array, default 0 |
| `o` | | offset, default 0 |
| `c` | | max results, default 0 = **all** |

```json
[
  {
    "Title": "Advanced Busterhawk: Gley Lancer",
    "ID": 3684,
    "ConsoleID": 1,
    "ConsoleName": "Mega Drive",
    "ImageIcon": "/Images/020895.png",
    "NumAchievements": 44,
    "NumLeaderboards": 33,
    "Points": 595,
    "DateModified": "2022-11-20 03:44:12",
    "ForumTopicID": 1936,
    "Hashes": ["8bd4a97783cda077c342173df0a9b51e", "a13ab653a20fb383337fab1e52ddb0df"]
  }
]
```

`c=0` on a big system with `h=1` returns a very large payload — page it (`c=500`) rather than pulling everything into memory on a 2 GB VPS. There is no name-search endpoint: mirror this list and search locally.

---

## API_GetConsoleIDs — `?a=1&g=1`

| Param | Req | Description |
| :-- | :-- | :-- |
| `a` | | 1 = only active systems, default 0 |
| `g` | | 1 = only real gaming systems (excludes Hubs, Events, …), default 0 |

```json
[
  {
    "ID": 1,
    "Name": "Mega Drive",
    "IconURL": "https://static.retroachievements.org/assets/images/system/md.png",
    "Active": true,
    "IsGameSystem": true
  }
]
```

`IconURL` is absolute (unlike every other image field). Call this first and cache it; system IDs are stable but names drift (`"Mega Drive"` vs `"Genesis/Mega Drive"` vs `"Mega Drive / Genesis"` appear in different endpoints — **never join on console name, join on `ConsoleID`**).

IDs seen in the official examples (verify with the endpoint, don't hardcode a full table): 1 Mega Drive, 3 SNES, 5 Game Boy Advance, 7 NES, 12 PlayStation, 15 Game Gear, 18 Nintendo DS, 27 Arcade, 33 SG-1000, 41 PlayStation Portable, 76 PC Engine CD. Non-game "systems" (Hubs, Events, Standalones) share the same ID space — that is what `g=1` filters out.

---

## API_GetGameRankAndScore — `?g=14402&t=0`

| Param | Req | Description |
| :-- | :-- | :-- |
| `g` | yes | game ID |
| `t` | | 1 = latest masters, 0 = non-master high scores (default) |

Ordering matters: with `t=1` the first entry is the **most recent** mastery; with `t=0` the first entry is the **first person** to master the set.

```json
[
  { "User": "Arekdias", "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ", "NumAchievements": 15, "TotalScore": 219, "LastAward": "2023-06-07 14:43:18" }
]
```

---

## API_GetGameProgression — `?i=228&h=1`

Median unlock times — the data behind "how long to beat/master". Times are in **seconds**.

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |
| `h` | | 1 = prefer players with more hardcore than softcore unlocks |

```json
{
  "ID": 228,
  "Title": "Super Mario World",
  "ConsoleID": 3,
  "ConsoleName": "SNES/Super Famicom",
  "ImageIcon": "/Images/112443.png",
  "NumDistinctPlayers": 79281,
  "TimesUsedInBeatMedian": 4493,
  "TimesUsedInHardcoreBeatMedian": 8249,
  "MedianTimeToBeat": 17878,
  "MedianTimeToBeatHardcore": 19224,
  "TimesUsedInCompletionMedian": 155,
  "TimesUsedInMasteryMedian": 1091,
  "MedianTimeToComplete": 67017,
  "MedianTimeToMaster": 79744,
  "NumAchievements": 89,
  "Achievements": [
    {
      "ID": 342,
      "Title": "Giddy Up!",
      "Description": "Catch a ride with a friend",
      "Points": 1,
      "TrueRatio": 1,
      "Type": null,
      "BadgeName": "46580",
      "NumAwarded": 75168,
      "NumAwardedHardcore": 37024,
      "TimesUsedInUnlockMedian": 63,
      "TimesUsedInHardcoreUnlockMedian": 69,
      "MedianTimeToUnlock": 274,
      "MedianTimeToUnlockHardcore": 323
    }
  ]
}
```

Here `Achievements` is an **array** (unlike GameExtended's map) and uses `Type` with a capital T. `TimesUsedIn*Median` = sample size behind each median; a median computed from 3 players is noise — check it before displaying.

---

## API_GetAchievementCount — `?i=14402`

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |

```json
{ "GameID": 14402, "AchievementIDs": [79434, 79435, 79436, 325413, 325414, 325415] }
```

Tiny payload — the right way to detect a **set revision** (count went from 100 to 102 → the set changed) before refetching `API_GetGameExtended`.

---

## API_GetAchievementDistribution — `?i=14402&h=1&f=3`

| Param | Req | Description |
| :-- | :-- | :-- |
| `i` | yes | game ID |
| `h` | | 1 = hardcore unlocks only, 0 = all (default) |
| `f` | | 3 = official (default), 5 = unofficial |

Map: **"number of achievements earned" → "number of players who earned exactly that many"**.

```json
{ "1": 141, "2": 51, "3": 41, "4": 49, "5": 57, "13": 6, "14": 3, "15": 8 }
```

The entry at key `NumAchievements` is the mastery count; divide by `NumDistinctPlayers` for mastery rarity. Players with zero unlocks are not in the map.
