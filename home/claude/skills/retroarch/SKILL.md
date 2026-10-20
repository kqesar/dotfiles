---
name: retroarch
description: Offline reference for driving and reading RetroArch from an external process — its UDP command interface (GET_STATUS, READ_CORE_MEMORY vs READ_CORE_RAM, PAUSE_TOGGLE, SCREENSHOT), the retroarch.cfg keys that matter and where the file lives per install layout, the rcheevos log lines that announce unlocks, leaderboard attempts and whether RA recognises the loaded ROM, and the rcheevos trigger language (MemAddr/VAL serialisation, flags, AddSource accumulators, AndNext/OrNext chaining). Use it whenever a task touches RetroArch, libretro cores, emulated RAM reading, retroarch.cfg, a RetroArch log, achievement/leaderboard integration in an emulator, or a codebase that already talks to RetroArch — in any language. STRICT SCOPE: do not load on projects unrelated to RetroArch or libretro. Pairs with the retroachievements-api skill when the task also touches retroachievements.org.
---

# RetroArch, from the outside

Everything here is verified against a real RetroArch 1.22.2 session (AppImage,
snes9x core, Linux/Wayland) unless a line says otherwise. It is the knowledge
that is expensive to rediscover: undocumented command semantics, log formats
that are not an API contract, and config keys whose names do not say what they
do.

## Keeping this file honest

**If reality disagrees with anything below, reality wins.** Fix the line, note
what changed and how it was observed, in the same pass as the task that found
it. A reference nobody corrects is worse than no reference: it is trusted and
wrong. Two entries here already exist because an earlier version of this file
(and of the `retroachievements-api` skill) asserted something false.

---

## The UDP command interface

The only supported way to drive a running RetroArch from another process.

**Enabling it** — in `retroarch.cfg`:

```
network_cmd_enable = "true"
network_cmd_port = "55355"
```

**Security, stated plainly**: it is **unauthenticated and bound to all
interfaces**, not just loopback. Anyone who can reach the port can read emulated
memory, load save states and quit the emulator. On a trusted LAN this is usually
tolerable; on anything else, firewall the port. There is no auth option.

**Protocol**: one UDP datagram per command, ASCII, no framing, reply is one
datagram. No connection, no ordering guarantee, no flow control.

### Commands worth knowing

| Command | Reply | Notes |
| :-- | :-- | :-- |
| `GET_STATUS` | `GET_STATUS <state> <system>,<game>[,<crc32>]` | `CONTENTLESS` comes alone (`GET_STATUS CONTENTLESS`). `state` is `PAUSED`, `PLAYING` or `CONTENTLESS`. `<system>` is the core's `systemid` (`super_nes` for every SNES core), so it cannot tell cores apart. `<game>` is the content's basename without extension, **commas unescaped**: take everything between the first comma and `,crc32=`. Split on every comma, `Legend of Zelda, The - A Link to the Past (USA)` came back as `Legend of Zelda`. To tie it to a path (log, playlist), compare as a prefix. The crc32 field may be absent (seen with content started via `-L`) |
| `READ_CORE_MEMORY <hexaddr> <n>` | `READ_CORE_MEMORY <hexaddr> <hex bytes>` | needs the core to publish a `retro_memory_map` |
| `READ_CORE_RAM <hexaddr> <n>` | `READ_CORE_RAM <hexaddr> <hex bytes>` | legacy, routes through rcheevos' address translation |
| `WRITE_CORE_MEMORY <hexaddr> <hex bytes>` | `WRITE_CORE_MEMORY <hexaddr> <n>` | |
| `PAUSE_TOGGLE`, `RESET` | none | fire-and-forget. `RESET` was seen to do nothing (2026-10-19, 1.22.2, bsnes-mercury, Super Metroid in play: still in play 6 s later, per `$7E:0998`): confirm its effect from memory, never assume it |
| `QUIT` | none | with `confirm_quit = "true"` it only opens the confirmation dialog: the process stays up. `SIGTERM` to the `retroarch` process exits cleanly — under an AppImage see "Stopping an AppImage" below |
| `SCREENSHOT` | none | writes to RetroArch's screenshot directory |
| `SAVE_STATE`, `LOAD_STATE`, `STATE_SLOT_PLUS/MINUS` | none | |
| `VERSION` | version string | cheapest liveness probe |

`GET_STATUS` is the reliable "is a game loaded?" signal. **`CONTENTLESS` means
the menu**, so a HUD or overlay must key visibility off this rather than off
"is the process alive".

A second RetroArch instance starts without complaint while the first still
holds the port; replies then came from the newest one. Before trusting a reply,
make sure only one instance runs (`pgrep -fa retroarch`).

Note `PAUSED` also fires when the window merely loses focus, because
`pause_nonactive = "true"` is the default. Do not treat `PAUSED` as "the player
stopped playing"; treat it as "frames are not advancing right now".

### Stopping an AppImage

An AppImage runs as **two processes with the same command line**: RetroArch
itself (`comm` = `AppRun`), the one answering UDP, and the AppImage runtime
serving its FUSE mount (`comm` = `RetroArch.AppIm`). SIGTERM the `AppRun` one;
it exits 0. Killing the runtime first leaves RetroArch running on a dead mount:
it still answers, then dies with **SIGBUS (exit 135)** when it exits (observed
on 1.22.2, 2026-10-17).

Pick the PID by `comm`, never by a `pgrep -f` pattern: the shell running the
command carries that pattern in its own command line, so `pgrep -f
"RetroArch.AppImage.*AppRun"` matched the calling shell, and the SIGTERM killed
it (exit 144) while RetroArch kept running (observed 2026-10-17). This works:

```sh
ps -eo pid,comm,args | awk '$2 == "AppRun" && /RetroArch\.AppImage/ { print $1 }'
```

### Testing against a real session without touching the player's setup

- **`--appendconfig=<file>`** layers overrides on `retroarch.cfg` for one run.
  With `config_save_on_exit = "false"` in it, the player's config is not
  rewritten (its mtime stayed put). Useful overrides: `video_fullscreen`,
  `pause_nonactive = "false"`, and `savefile_directory` /
  `savestate_directory` pointed at a scratch copy, so in-game SRAM written on
  exit never lands on the player's saves. `screenshot_directory` there sends
  the `SCREENSHOT` command's files to that copy too (seen 2026-10-19).
- **Pressing buttons with no input tool** (Wayland, no ydotool): the network
  remote gamepad. With `network_remote_enable = "true"`,
  `network_remote_enable_user_p1 = "true"` and `network_remote_base_port =
  "55400"`, one UDP datagram to `55400 + player` sets one button:
  `struct.pack("<iiiiH2x", port=0, device=1 (JOYPAD), index=0, id, state)`,
  `id` from `RETRO_DEVICE_ID_JOYPAD_*` (B 0, Y 1, SELECT 2, START 3, UP 4,
  DOWN 5, LEFT 6, RIGHT 7, A 8, X 9, L 10, R 11); send `state` 1, wait
  ~100 ms, send 0. Verified on ALttPR: START → file select (`$7E0010` = $01),
  START → spawn menu ($1B), A → in play ($07). In play, START opens the item
  menu (mode $0E, submode $01) and SELECT the save prompt ($0E, $0B; SELECT
  inside the item menu does nothing): DOWN, A saves and quits to $00. Until
  a file loads again, the save data's WRAM copy ($7EF000+) reads 0
  (observed 2026-10-18).

### READ_CORE_MEMORY vs READ_CORE_RAM — the distinction that matters

They are **not interchangeable**, and the difference decides whether an address
from an achievement definition means anything.

- `READ_CORE_MEMORY` uses the core's `retro_memory_map`. Many cores do not
  publish one — **snes9x does not**, and answers `no memory map defined`.
  **bsnes-mercury does**, over the full SNES A-bus, ROM banks included:
  `READ_CORE_MEMORY 308210 16` on a LoROM ALttPR ROM returned the bytes at file
  offset `0x180210`, and `7e0010` returned live WRAM. This is the core SNI's
  RetroArch driver relies on.
- `READ_CORE_RAM` is the legacy command and routes through **rcheevos' own
  address translation**. Its addresses are therefore *RA addresses*: exactly the
  ones achievement logic, rich-presence scripts and leaderboard values are
  written against.

So: if you are reading memory to evaluate RetroAchievements logic, `READ_CORE_RAM`
is the one whose address space already matches. Probe `READ_CORE_MEMORY` once per
session and fall back — it is the supported command and the legacy one may
eventually go.

Measured on snes9x: `READ_CORE_RAM` covers `0x00000-0x1FFFF` (WRAM) and `0x20000+`
(SRAM), matching the regions rcheevos logs at game load.

### Reply handling

- A failed read answers `-1` in the value position, not an error. With
  `READ_CORE_MEMORY` an error text follows it: `-1 no memory map defined` (a core
  without a memory map, **and also RetroArch with no content loaded**: tell them
  apart with `GET_STATUS`), `-1 no data for descriptor` (an I/O register such as
  `$2100`). `READ_CORE_RAM` answers a bare `-1` (all observed 2026-10-19, 1.22.2).
- **Match replies on the echoed address**, never on arrival order. A late answer
  to a previous request is otherwise read as the answer to the current one, and
  the two carry different bytes. The echo is **normalised** (`%x`, no padding):
  `READ_CORE_MEMORY 00ffc0 32` is answered `READ_CORE_MEMORY ffc0 …`, so compare
  addresses as numbers, never as strings.
- A read running past the end of the core's memory descriptor comes back
  **short, silently**: `7ffff0 32` returned 16 bytes. Count the bytes.
- Reply size: `READ_CORE_MEMORY` answered 8192, 16384 and 20000 bytes in one
  datagram (60,024 bytes) on 1.22.2 with bsnes-mercury (observed 2026-10-19).
  An earlier version of this file said 4096 bytes and that larger replies are
  dropped; that is false there. The source agrees: `command.c` (v1.22.2,
  `command_read_memory`, `command_read_ram`) allocates `nbytes * 3` and caps
  nothing but the descriptor's end; no `COMMAND_READ_NBYTES_MAX` exists. The
  real ceiling is the UDP datagram (~65,500 bytes, three characters a byte):
  above ~21,800 bytes the reply cannot be sent. 4096 remains a sensible span cap.
- With nothing listening on the port, a **connected** UDP socket fails at once
  (`ECONNREFUSED` on `recv`, 0 ms on Linux): a liveness probe need not wait out
  a timeout.
- Reads are served while `PAUSED` (`PAUSE_TOGGLE`, then a read: answered).
- Requests are serviced on **RetroArch's main loop**, so the cost lands on the
  player's frame timing. The *number* of requests matters far more than the bytes:
  coalescing scattered addresses into a few wide reads is almost always the right
  trade.
- Several requests may be **in flight at once** — the echoed-address matching
  makes that unambiguous — and doing so overlaps the round trips instead of
  paying them in series. Bound it (≈8): UDP has no flow control, and a large
  burst competes with the frame being drawn. Commands are serviced once per
  frame: one at a time costs ~16 ms each, while 16 sent together on 16 sockets
  were all answered in 2.6 ms (1.22.2, bsnes-mercury, 2026-10-19).

**Measured** (SNES, A Link to the Past, 343 distinct addresses coalesced with a
512-byte merge gap): 4 requests / 3,635 bytes per poll; ~6 ms per poll wall time
at 8 in flight; evaluation of 109 compiled triggers ~0.4 ms. At 4 Hz the whole
loop costs well under 1 % of one core.

---

## `retroarch.cfg`

### Where it lives

Probe in this order; the layouts differ per install method:

| Install | Path |
| :-- | :-- |
| Native | `~/.config/retroarch/retroarch.cfg` |
| Flatpak | `~/.var/app/org.libretro.RetroArch/config/retroarch/retroarch.cfg` |
| AppImage (portable) | `<AppImage>.home/.config/retroarch/retroarch.cfg` |

### The trap: RetroArch rewrites it on exit

RetroArch holds its configuration in memory and **writes the whole file out when
it quits**, overwriting anything edited while it was running. Change settings
through the menu, or edit only while it is closed. This costs people an hour
regularly.

### Keys that matter

| Key | Why |
| :-- | :-- |
| `network_cmd_enable`, `network_cmd_port` | the command interface above |
| `cheevos_enable` | RetroAchievements on/off |
| `cheevos_hardcore_mode_enable` | the session's mode at launch — no RA API endpoint reports it. Rewritten only on exit, so it misses a mid-session switch; the log does not (see *Which mode is running*) |
| `cheevos_username`, `cheevos_token` | RA Connect credentials. `cheevos_token` is an account credential: never log it, never write it to a state file or cache |
| `cheevos_richpresence_enable` | whether RetroArch uploads rich presence |
| `cheevos_appearance_anchor` | `0`–`5`: top-left, top-centre, top-right, bottom-left, bottom-centre, bottom-right. One anchor drives both notifications and leaderboard trackers, which RetroArch mirrors from it |
| `cheevos_appearance_padding_auto`, `cheevos_appearance_padding_h/v` | manual placement, once auto is off |
| `log_to_file`, `log_verbosity` | both `"true"` are required for the log tap below |
| `log_dir`, `log_to_file_timestamp` | where, and whether a new file per launch |
| `pause_nonactive` | default `"true"`; why `GET_STATUS` says `PAUSED` on focus loss |
| `confirm_quit` | when `"true"`, the `QUIT` command waits on a dialog instead of quitting |
| `video_monitor_index` | 1-based; maps to an output name only by convention — confirm with `kscreen-doctor -o` or equivalent, do not assume index alignment |

---

## The log: the only sub-second event source

With `log_to_file` and `log_verbosity` on, RetroArch writes `[RCHEEVOS]` lines
that announce achievement and leaderboard events **as they happen locally**. This
matters because RetroAchievements' servers only learn about an unlock *after*
RetroArch uploads it, and the web API has no push channel at all — no SSE, no
websocket, no webhook. Tailing the log is the only way to know first.

It is **not an API contract**. Treat every parse as best-effort and degrade to
polling when the log is absent, disabled or silent.

**File name**: `retroarch.log`, or `retroarch__YYYY_MM_DD__HH_MM_SS.log` when
`log_to_file_timestamp` is on — in which case a new file appears per launch, so
re-resolve "newest file" periodically rather than once.

### Line formats

```
[INFO] [RCHEEVOS] Awarding achievement 12345: Some Title
[INFO] [RCHEEVOS] Achievement 12345 awarded, new score: 4200
[INFO] [RCHEEVOS] Leaderboard 65174 started: Moldorm Speedrun
[INFO] [RCHEEVOS] Leaderboard 65174 canceled: Moldorm Speedrun
[INFO] [RCHEEVOS] Submitting 0:16.10 (966) for leaderboard 65174: Moldorm Speedrun
[INFO] [RCHEEVOS] Disabled leaderboard 65174. Invalid address 00f36d
```

- **Two lines describe one unlock** and either may come first; match both and
  deduplicate on the id, keeping whichever carries the title.
- Failures use the same words in a different case (`Error awarding achievement
  12345: …`). Filter on `Error`, or a failed unlock reaches your UI as a
  success. Only the *submit* line may legitimately share a line with an error.
- The submit line carries **both the formatted value and the raw one**, so the
  final figure can be RetroArch's own rather than your approximation.

### Does RA know this ROM? The identification lines

Observed 2026-10-16 (RetroArch 1.22.2, bsnes-mercury), with an ALttP randomizer
seed and the original cartridge, replayed over 14 real sessions:

```
[INFO] [RCHEEVOS] Identifying game: 2097152 bytes at 0x12008680 (/roms/alttpr/seed.sfc)
[INFO] [RCHEEVOS] Identified game: 355 "The Legend of Zelda: A Link to the Past" (<md5>)
[INFO] [RCHEEVOS] Load failed (-29): Unknown game
[INFO] [RCHEEVOS] Game not recognized, pausing hardcore
[INFO] [RCHEEVOS] Unloading game 0
```

- This is the **only generic "RA does not know this hash" signal**. The web API
  never says so: it keeps describing the user's previous game, so a
  "has RA caught up?" check waits forever on a randomizer, a hack or a prototype.
- `Identifying game` carries the content path; an archive member reads
  `set.zip#rom.sfc`, and the path may contain parentheses. Use it to tie a
  verdict to the `GET_STATUS` content, since the two channels can race.
- `Unknown game` is rcheevos' wording, `Game not recognized` RetroArch's. Match
  both. Any *other* `Load failed` (no network) says nothing about the ROM.
- `Identified game: N` carries **RA's game id**, the one the web API uses (355
  in both for ALttP). It lands seconds before the web API's user summary names
  the game — `LastGameID` moves only once RA has registered the session, ~4.6 s
  after load — so it is the earliest way to know which game is loaded: query the
  game endpoints by that id rather than waiting on the summary.
- `Unloading game N` (`0` for an unknown ROM) ends the content's lifetime.
- The verdict lands a second or two after load, typically **before** a process
  that just noticed a new timestamped log file has attached to it. Read it as
  state from the file's backlog, not as an event from its tail.
- The `(<md5>)` closing the `Identified game` line is the content's RA hash —
  the key for Connect `r=achievementsets`, which lists the bonus sets the content
  runs (see the `retroachievements-api` skill). With a subset, the load also
  logs one line per set: `Set 368: 35/109 achievements active, 16 leaderboards`
  then `Set 38555: 14/14 achievements active, 0 leaderboards` (observed
  2026-10-18): **both run at once**; there is no "subset mode".

### Which mode is running: hardcore lines

Observed 2026-10-18 (1.22.2, snes9x, ALttP): launch with the setting off, switch
on in Settings > Achievements, pause then resume from the Quick Menu's
achievement list.

```
[INFO] [RCHEEVOS] Hardcore disabled                       setting off, at launch
[INFO] [RCHEEVOS] Load started, hardcore not active       (hardcore on: "hardcore active")
[INFO] [RCHEEVOS] Game 355 loaded, hardcore disabled      (hardcore on: "hardcore enabled")
[INFO] [RCHEEVOS] Hardcore enabled, waiting for reset     switched on mid-game; the core resets next
[INFO] [RCHEEVOS] Resetting runtime
[INFO] [RCHEEVOS] Hardcore disabled                       paused mid-game
```

- Check the "not active" / "disabled" forms first: "hardcore not active" also
  contains "hardcore … active".
- A launch with the setting on logs no bare `Hardcore enabled`; the load lines
  carry it.
- An unknown ROM logs `pausing hardcore` then `Hardcore disabled`: right, since
  nothing can be earned on it.
- Treat the mode as per-launch state, read from the backlog like the verdict,
  and trust it only while the verdict matches the content `GET_STATUS` reports —
  a tail still on the previous launch's file would otherwise speak for this one.
- No network command toggles it (`CHEEVOS_HARDCORE_MODE_TOGGLE` is answered
  "Commande non reconnue"); driving the menu does: with
  `menu_swap_ok_cancel_buttons` on, `MENU_B` confirms and `MENU_A` goes back.

### What the log does NOT carry

- **Measured progress** ("37/100"). That is an `rc_client` event RetroArch
  consumes to draw its own widget; it is never logged and never exposed by the
  web API. It must be recomputed from emulated RAM.
- **Primed / challenge-indicator state**, for the same reason.
- A leaderboard's *running value*, which is usually a per-frame counter inside
  rcheevos. The log gives the two ends; a wall clock anchored on `started` is the
  only way to fill the middle, and it drifts under fast-forward, rewind or slow
  motion.

### The unlock screenshot RetroArch already takes

With `cheevos_auto_screenshot = "true"`, RetroArch saves a capture at the
moment of every unlock, **named after the achievement**:

```
<screenshot_directory>/<content basename>-cheevo-<achievementId>.png
```

e.g. `Legend of Zelda, The - A Link to the Past (USA)-cheevo-2192.png`, a
256×224 PNG at native resolution. Observed on 1.22.2 (2026-10-18): 67 such files,
every id matching an unlock in a separate session log. Hardcore unlocks are
captured too. With `sort_screenshots_by_content_enable` on, the file lands in a
per-content subdirectory instead.

So an external process that wants "the picture of this unlock" should **look it
up by id** rather than send `SCREENSHOT` over UDP and guess which new file
belongs to which unlock: the id in the name makes the association exact, where
timing correlation is ambiguous the moment two unlocks cascade. A later unlock
of the same id (softcore, then hardcore) overwrites the file.

---

## The rcheevos trigger language

An achievement's `MemAddr`, a leaderboard's `VAL:` section and a rich-presence
script all use the same serialisation. Getting these details wrong produces
plausible, wrong numbers rather than errors.

### Shape

- Conditions joined by `_`; **alt groups** joined by a bare `S`.
  **`0xS` is also the bit-6 size prefix**, so split on `S` not preceded by `0x`
  (lookbehind), or any set using bit 6 is silently corrupted.
- Trailing `.20.` on a condition is a **hit target**: the comparison must hold
  for 20 frames. The closing dot is not decoration — without it the pattern also
  swallows the scale factor in `0xH0204*0.125`.
- The trigger fires when the core group holds **and** at least one alt group
  holds (or there are no alts).

### Size prefixes

`0xM`–`0xT` = bits 0–7 · `0xL`/`0xU` = low/high nibble · `0xH` = 8-bit ·
`0x` = 16-bit · `0xW` = 24-bit · `0xX` = 32-bit · `0xK` = bit count (population
count of one byte — set authors use it for "how many pendants do you have").

### Flags

`A:` AddSource · `B:` SubSource · `N:` AndNext · `O:` OrNext · `Q:` MeasuredIf ·
`M:` Measured · `G:` Measured-as-percentage · `T:` Trigger · `R:` ResetIf ·
`Z:` ResetNextIf · `P:` PauseIf · `C:` AddHits · `D:` SubHits ·
`I:` AddAddress (pointer chain) · `K:` Remember (recall accumulator).

### Two semantics that are routinely implemented wrong

**`AndNext`/`OrNext` chain into the condition that *follows*** them, rather than
combining the two already seen. Judging each link independently is correct for
AND and **catastrophic for OR**: a gate written `O:MapID=0_MapID=255`
("overworld *or* indoors") has exactly one true branch at any time, so
independent evaluation leaves it permanently false. Observed symptom: one
achievement's progress counter never appears while a structurally similar one
works, because the second happened to use plain conditions.

**`AddSource`/`SubSource` accumulate into the condition that closes the chain.**
`A:x_A:y_0>51` asks whether `x+y > 51`; the literal `0` is just the accumulator
terminator. Two consequences:

- A gate closing a chain must be evaluated *with* the accumulator, or it is
  always false.
- A condition ending a chain is **meaningless in isolation**. `M:0xQ00f248=35`
  is thirty-four chest bits summed, not "bit 4 equals 35". Never render one on
  its own as if it were a standalone comparison.

### `AddAddress` is a pointer chain, and the accumulator *replaces*

`I:` reads a pointer; every **following** condition treats its own declared
address as an offset from that pointer rather than as an absolute address. Two
details decide whether an implementation is right or merely plausible:

- **Replace, do not add.** `I:ptrA_I:ptrB_0xH10=5` means: read the pointer at
  `ptrA` → `p1`; read the pointer at `ptrB + p1` → `p2`; test the byte at
  `0x10 + p2`. Accumulating instead (`p1 + p2`) reads an unrelated address and
  returns a number that looks fine.
- **The accumulator resets after the first non-`I:` condition**, so one chain
  serves exactly one condition unless it is repeated.

The offset applies to **both sides** of the comparison, and to the `I:`
condition's own operand — which is what makes chaining work at all.

Consequences for an external reader: the addresses are not knowable in advance,
so a fixed span plan cannot contain them. Collect only the chain's *first* link
as a fixed address, then read in rounds — resolve what the snapshot allows, fetch
those addresses, repeat — bounding the rounds to cap the deepest chain followed.
Declaring the offset as if it were absolute is the failure mode to avoid: it
fetches real memory from the wrong place.

`delta`/`prior` behind a pointer needs no special case. The previous snapshot
either holds the same absolute address (the pointer did not move, and the
comparison is right) or it does not, and the read fails, dropping that item for
that poll.

**How much it matters, measured across eleven sets** (a downstream project, 2026-08-20):
Metal Gear Solid uses `I:` in **all 112** of its achievements, Super Mario 64 in
26 %, GoldenEye 007 in 5 %, while A Link to the Past, Final Fantasy VII,
Symphony of the Night, Crash Bandicoot, Metroid Fusion, Golden Sun and Advance
Wars use it in none. It is **bimodal**: a set either barely uses pointers or is
built entirely on them, so "PS1/N64 needs it" is wrong as stated — three of four
PS1 sets sampled need nothing.

### An empty alt group is legal, and common

RA's editor serialises a **trailing `S`**, leaving an empty final alt group — 59
of GoldenEye 007's 141 achievements end in one. Treat it as a condset of zero
conditions: a conjunction of nothing is true, so the trigger fires on its core
group alone. Rejecting it as a parse error discards the whole achievement, and
the symptom is silence rather than an error — the trigger simply never appears,
which is indistinguishable from a set that has none.

Refuse only a trigger whose *every* group is empty: vacuously true everywhere, it
would read as permanently firing.

### Sampling from outside is not frame-accurate

An external process reading RAM a few times a second cannot reproduce rcheevos
exactly, and the two error directions differ:

- **Hit counts under-count** — one sample contributes at most one hit, so a
  target of 20 frames needs 20 samples. Targets of 1 (a latch, "did this ever
  happen") behave correctly. Under-counting only ever *delays*, which is safe.
- **A `ResetIf` true for a single frame can be missed**, which is the unsafe
  direction. Mitigated in practice because most resets are level conditions that
  stay true, and because an external `delta` means "the previous poll" — a far
  wider window than one frame.
- **Edge conditions (`X > d(X)`) are essentially never observed.** This is how RA
  writes "you picked the item up". Such a trigger stays permanently one condition
  short from the outside; it is still a true statement of what is missing, and it
  clears when the real rcheevos fires the unlock.

Therefore: publish measured values (pure functions of a snapshot) as exact, and
anything depending on hit counts or resets as best-effort. Keep the two apart in
code — a single "is this stateless?" predicate is the natural boundary.

---

## Getting the achievement logic and the address names

Both come from RetroAchievements' Connect API, using the `cheevos_username` /
`cheevos_token` pair already in `retroarch.cfg`. **See the
`retroachievements-api` skill, `references/connect-api.md`**, for the request
shapes and response schemas:

- `dorequest.php?r=patch` — the real `MemAddr` and rich-presence script. The
  public web API returns MD5 hashes of both, deliberately.
- `dorequest.php?r=codenotes2` — per-address descriptions written by the set's
  developers. This is what turns `0xH00f343>d0xH00f343` into
  `Bombs possessed ↑`. 736 notes on A Link to the Past, ~86 % coverage of the
  addresses a full trigger compilation touches.

Both are emulator-only calls: not a public contract, once per game, cached on
disk, failure means "feature off".

---

## Checklist for a new integration

1. `VERSION` over UDP to confirm the command interface answers at all.
2. `GET_STATUS` on a slow cadence (~2 s) for load/menu/pause state.
3. Read `retroarch.cfg` for hardcore mode, credentials and log settings — and
   re-read it, cheaply, because RetroArch rewrites it on exit.
4. Probe `READ_CORE_MEMORY`, fall back to `READ_CORE_RAM`, remember which.
5. Plan address spans; coalesce aggressively; cap per-span at 4096 bytes (a
   comfortable margin, not a RetroArch limit: see "Reply handling") and bound
   concurrency at ~8.
6. Tail the log for unlocks, leaderboard brackets and whether RA knows the ROM
   at all; degrade to polling without it.
7. Fetch `r=patch` (and `r=codenotes2` if you render conditions) once per game,
   cache on disk.
