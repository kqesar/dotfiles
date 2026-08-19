# Web API — tickets & set claims

Base: `https://retroachievements.org/API/`. `y` required everywhere and omitted below.

Domain context: a **ticket** is a bug report against an achievement (didn't trigger, triggered at the wrong time…). A **claim** is a developer reserving a game to build or revise its achievement set. Both are dev-workflow data — relevant for dashboards and dev tooling, not for player-facing features.

---

## API_GetTicketData — one PHP file, six modes

`API_GetTicketData.php` switches behaviour on which selector you pass. Passing the wrong combination silently gives you a different mode, so be explicit.

| Mode | Selector |
| :-- | :-- |
| Ticket by ID | `i=<ticketId>` |
| Achievement ticket stats | `a=<achievementId>` |
| Game ticket stats | `g=<gameId>` (+ `f=5`, `d=1`) |
| Developer ticket stats | `u=<username or ULID>` |
| Most recent tickets | no selector (+ `c`, `o`) |
| Most ticketed games | `f=1` (+ `c`, `o`) |

### Mode: ticket by ID — `?i=12345`

```json
{
  "ID": 12345,
  "AchievementID": 11843,
  "AchievementTitle": "A good Beginning 2",
  "AchievementDesc": "Your Partner Pokemon reaches Level 10.",
  "AchievementType": null,
  "Points": 3,
  "BadgeName": "309094",
  "AchievementAuthor": "tuteur51",
  "AchievementAuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
  "GameID": 2816,
  "ConsoleName": "Game Boy Advance",
  "GameTitle": "Pokémon Mystery Dungeon: Red Rescue Team",
  "GameIcon": "/Images/050264.png",
  "ReportedAt": "2018-04-11 08:15:55",
  "ReportType": 1,
  "ReportState": 2,
  "Hardcore": null,
  "ReportNotes": "Right before going to Thunderwave Cave, all three of these triggered at the same time.<br/>MD5: 9837da1fdfe900c52f2109d9718d4e85",
  "ReportedBy": "ThatOneEnderMan",
  "ReportedByULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
  "ResolvedAt": "2018-04-16 08:03:31",
  "ResolvedBy": "tuteur51",
  "ResolvedByULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
  "ReportStateDescription": "Resolved",
  "ReportTypeDescription": "Triggered at the wrong time",
  "URL": "https://retroachievements.org/ticket/12345"
}
```

`ReportState` / `ReportType` are numeric codes; the API ships the human label alongside (`ReportStateDescription`, `ReportTypeDescription`) — **use the descriptions**, the numeric mapping is not documented and has grown over time. Observed: state 1 = "Open", 2 = "Resolved"; type 1 = "Triggered at the wrong time", 2 = "Did not trigger". `Hardcore` may be `null` on old tickets. `ReportNotes` contains raw user text with embedded HTML (`<br/>`) — sanitise before rendering.

### Mode: achievement ticket stats — `?a=9`

```json
{
  "AchievementID": 284759,
  "AchievementTitle": "The End of The Beginning",
  "AchievementDescription": "Receive the Package from the King of Baron and begin your quest to the Mist Cavern",
  "AchievementType": "progression",
  "URL": "https://retroachievements.org/achievement/284759/tickets",
  "OpenTickets": 1
}
```

### Mode: game ticket stats — `?g=1&f=5&d=1`

| Param | Description |
| :-- | :-- |
| `g` | game ID (required for this mode) |
| `f` | 5 = ticket data for unofficial achievements |
| `d` | 1 = include deep ticket metadata in a `Tickets` array |

```json
{
  "GameID": 14402,
  "GameTitle": "Dragster",
  "ConsoleName": "Atari 2600",
  "OpenTickets": 0,
  "URL": "https://retroachievements.org/game/14402/tickets"
}
```

With `d=1` a `Tickets` array of full ticket objects (same shape as ticket-by-ID) is added.

### Mode: developer ticket stats — `?u=Hexadigital`

```json
{
  "User": "MockUser",
  "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
  "Open": 0,
  "Closed": 17,
  "Resolved": 27,
  "Total": 44,
  "URL": "https://retroachievements.org/user/MockUser/tickets"
}
```

Counts tickets against achievements this user **authored**. "Closed" (dismissed) and "Resolved" (fixed) are distinct outcomes.

### Mode: most recent tickets — `?o=0&c=10`

`c` default 10, max 100.

```json
{
  "RecentTickets": [
    {
      "ID": 64866,
      "AchievementID": 323665,
      "AchievementTitle": "DEFAULT SETTINGS CHECK",
      "AchievementDesc": "Normal or Hard difficulty, any character but \"Man\", any buster charge. All other settings OFF.",
      "AchievementType": null,
      "Points": 0,
      "BadgeName": "361407",
      "AchievementAuthor": "WCopeland",
      "AchievementAuthorULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "GameID": 24453,
      "ConsoleName": "Mega Drive",
      "GameTitle": "~Homebrew~ Mega Man: The Sequel Wars - Episode Red",
      "GameIcon": "/Images/074329.png",
      "ReportedAt": "2024-01-10 22:31:54",
      "ReportType": 2,
      "Hardcore": 1,
      "ReportNotes": "asdfasdf\nRetroAchievements Hash: bff0eb90c2006edade14063d4a2d13cf\nEmulator: RALibRetro (123123)\nEmulator Version: 123",
      "ReportedBy": "WCopeland",
      "ReportedByULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
      "ResolvedAt": null,
      "ResolvedBy": null,
      "ResolvedByULID": null,
      "ReportState": 1,
      "ReportStateDescription": "Open",
      "ReportTypeDescription": "Did not trigger"
    }
  ],
  "OpenTickets": 1109,
  "URL": "https://retroachievements.org/tickets"
}
```

Note the wrapper key is `RecentTickets`, not `Results` — this endpoint predates the `Count`/`Total`/`Results` convention.

### Mode: most ticketed games — `?f=1&c=10&o=0`

`f=1` is mandatory and selects the mode. `c` default 10, max 100.

```json
{
  "MostReportedGames": [
    { "GameID": 9701, "GameTitle": "Dead 'n' Furious | Touch the Dead", "GameIcon": "/Images/070109.png", "Console": "Nintendo DS", "OpenTickets": 12 }
  ],
  "URL": "https://retroachievements.org/manage/most-reported-games"
}
```

Key is `Console` here, `ConsoleName` elsewhere.

---

## API_GetActiveClaims

No params beyond `y`. All currently active set claims, **1000 max, unpaginated**.

```json
[
  {
    "ID": 11246,
    "User": "WanderingHeiho",
    "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "GameID": 26971,
    "GameTitle": "~Homebrew~ No Place To Hide",
    "GameIcon": "/Images/084916.png",
    "ConsoleID": 18,
    "ConsoleName": "Nintendo DS",
    "ClaimType": 0,
    "SetType": 0,
    "Status": 0,
    "Extension": 0,
    "Special": 0,
    "Created": "2023-10-27 23:27:16",
    "DoneTime": "2024-01-27 23:27:16",
    "Updated": "2023-10-27 23:27:16",
    "UserIsJrDev": 0,
    "MinutesLeft": -41266
  }
]
```

- `ClaimType`: 0 = primary, 1 = collaboration.
- `SetType`: 0 = new set, 1 = revision.
- `Status`: 0 = active, 1 = complete, 2 = dropped (matches the `k` values of `API_GetClaims` shifted by one — rely on which endpoint you called rather than on the code).
- `Extension` = how many times the claim was extended; `Special` marks event/special claims.
- `DoneTime` = the claim's expiry (claims run ~3 months). **`MinutesLeft` negative means expired** — active-but-expired claims do appear in this list.

## API_GetClaims — `?k=1`

| Param | Req | Description |
| :-- | :-- | :-- |
| `k` | | claim kind: 1 completed (default), 2 dropped, 3 expired |

Same row shape as `API_GetActiveClaims`, 1000 max, unpaginated.

```json
[
  {
    "ID": 11245, "User": "kmpers", "ULID": "00003EMFWR7XB8SDPEHB3K56ZQ",
    "GameID": 24541, "GameTitle": "GP World", "GameIcon": "/Images/076324.png",
    "ConsoleID": 33, "ConsoleName": "SG-1000",
    "ClaimType": 0, "SetType": 1, "Status": 1, "Extension": 0, "Special": 1,
    "Created": "2023-10-27 22:30:49", "DoneTime": "2023-10-27 23:21:12",
    "Updated": "2023-10-27 23:21:12", "UserIsJrDev": 0, "MinutesLeft": -173762
  }
]
```

Per-user claims: `API_GetUserClaims?u=<user>` (see `users.md`).
