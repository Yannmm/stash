# Synchronization

How Stash keeps the bookmark document in sync between this Mac and a remote backend (Dropbox, Baidu Pan,
iCloud). Source lives in `Stash/Synchronization/`; tests in `StashTests/SynchronizerTests.swift`.

## Model

**Local is the hub.** Every edit is written to the local copy first, and the app only ever reads the local
copy. A remote is a mirror that the [Synchronizer](#synchronizer) reconciles against.

Two files are synchronized, both in local and remote storage:

| File | Purpose |
|------|---------|
| `nustash_index.html` | The **document** — the bookmarks, as Netscape-format HTML. |
| `nustash_index.html.sidecar.json` | The **sidecar** — metadata describing which version the document is. |

Local files live in `~/Library/Application Support/Stash/`. Remote files live at the root of the
provider's app folder (`/` on Dropbox and Baidu Pan, `Documents/` in the iCloud container).

### Sidecar

```swift
struct Sidecar { uid: UUID; timestamp: Date; prettyTimestamp: String?; device: String }
```

- `uid` identifies a **version**. A new uid is stamped by every local edit (`Sidecar.stamp()`), and copied
  unchanged on push/pull. Two sides with the same uid hold the same document.
- `timestamp` is the wall-clock time of the edit on the editing device. It decides which side wins.
- `device` / `prettyTimestamp` are informational (history, debugging).

The sidecar is always written **after** the document, so a reader that sees a new sidecar can expect the
matching document to be in place.

## Components

```
                      ┌──────────────────────────────┐
  Housekeeper ──save──►         Synchronizer          ◄── setApproach (Settings)
       ▲      ◄─load──┤                                │
       │              │  Lane (serial queue)           │
   onChange           │  reconcile(provider, remote)   │
       │              │  History (sync_history.json)   │
       │              └───────┬───────────────┬────────┘
       │                      │               │
       │            LocalProvider         RemoteProvider (one active)
       └──onArrive── OnPremiseProvider     DropboxProvider ─┐
                                           BaiduPanProvider ┤ Polling
                                           AiCloudProvider  ┘ (file monitor)
```

| Type | File | Role |
|------|------|------|
| `Synchronizer` | `Synchronizer.swift` | Orchestrator. Owns the providers, decides push vs. pull, publishes status. |
| `Provider` | `Provider.swift` | Common read API: `sidecar()`, `document()`, `prepare()`, `pause()`. |
| `LocalProvider` | `Provider.swift` | Adds `write(html:)` (local edit, stamps a new sidecar) and `copy(document:sidecar:)` (apply a pull). `onArrive` fires after a pull so the UI reloads. |
| `RemoteProvider` | `Provider.swift` | Adds `send(document:sidecar:)` (push), `readiness`, `strayError`, and `onArrive: Sidecar?` (observed remote state). |
| `OnPremiseProvider` | `OnPremiseProvider.swift` | The only `LocalProvider`. Atomic file writes in Application Support. |
| `Polling` | `Polling.swift` | Mixin for remotes without push notifications (Dropbox, Baidu Pan). |
| `Lane` | `Lane.swift` | Serial async queue so sync operations never interleave. |
| `History` | `SyncHistory.swift` | Append-only audit log (last 100 entries) at `sync_history.json`. |
| `ProviderReadiness` | `Readiness.swift` | Per-provider "can I sync now" state (auth, reachability) plus its UI description. |
| `SyncError` | `SyncError.swift` | Errors. `fileNotFound` is special: callers treat it as "absent", not as failure. |

### Approach

`Synchronizer.Option` (`local`, `icloud`, `dropbox`, `baidupan`) is the user-selected backend. `local` means
no remote — edits stay on this Mac. Only one remote is active at a time; switching calls `pause()` on the
old provider and `prepare()` on the new one. All remote event streams are wired through `switchToLatest`,
so events from an inactive provider are ignored.

## Reconcile

All decisions about moving data live in one method, `Synchronizer.reconcile(provider:remote:)`. It
compares the local sidecar with the given remote sidecar and does at most one transfer.

Policy: **last writer wins by timestamp, uid checked first.**

| Local sidecar | Remote sidecar | Action |
|---------------|----------------|--------|
| absent | absent | nothing |
| present | absent | **push** |
| absent | present | **pull** |
| uid equal | uid equal | nothing (in sync) |
| newer timestamp | older | **push** |
| older or equal timestamp | newer or equal | **pull** (a tie with different uids pulls, so devices converge) |

Guards:

- **Push** skips (and logs `skip push_to_…`) if the local document is missing or empty.
- **Pull** skips (and logs `skip download_from_…`) if the remote document is empty — an empty remote never
  wipes local data.
- **Pull** with a remote sidecar but no remote document raises `SyncError.fileNotFound` — that is an
  abnormal remote state and is surfaced to the user.

Successful transfers are logged to `History` as `push_to_<option>` / `download_from_<option>`. Errors are
sent to the status line as `reconcile: <description>`.

`reconcile` takes the `provider` explicitly instead of reading the current approach, so if the user
switches backend mid-operation, the sidecar and the document always come from the same provider.

### Why there is no ping-pong

After a push or a pull, both sides hold the same sidecar (same uid), so the next reconcile is a no-op.
Transfers never stamp a new sidecar — only `LocalProvider.write(html:)` does.

## Triggers

Reconcile runs from three places. All go through the `Lane`.

### 1. Readiness

When the active remote's `readiness` becomes ready (login finished, network back, iCloud reachable), after
a 500 ms debounce, the Synchronizer fetches the remote sidecar itself and reconciles. This covers app
launch and switching backend.

### 2. Poll tick / remote change (`onArrive`)

- **Dropbox, Baidu Pan** (`Polling`): every `polinterval` (10 s) the provider downloads the remote sidecar
  and emits it on `onArrive` — **on every tick, even if unchanged**, and `nil` if the remote has no sidecar.
  Emitting every tick is what lets the Synchronizer *push* when local is newer, not only pull when remote
  is newer. Deciding is the Synchronizer's job; the poller does no deduplication.
- **iCloud**: a file monitor emits the sidecar when the iCloud copy changes.

These ticks are enqueued as **droppable**: if a tick is already waiting or running, new ticks are discarded
(the next one retries). This stops slow networks from building a backlog.

### 3. Save

`save(document:)` writes locally (`local_edit`), then pushes directly to the active remote. If the push
fails (offline, expired token), the local copy is newer than remote, and the next poll tick or readiness
event pushes it. Saves are **never dropped**.

## Polling loop

`Polling.startpol()` runs a `Task` until `pausepol()`:

```
loop:
  poll()              # sidecar() → onArrive; fileNotFound → onArrive(nil)
  on error: onPollError (→ strayError on the status line), failures += 1
  on success: failures = 0
  sleep polinterval × 2^min(failures, 5)     # 10 s … 320 s
```

- The sleep happens on every iteration, success or error, so errors never cause a hot loop.
- A missing remote sidecar is not an error — it is how a fresh remote gets its first push.
- Providers start polling once authenticated (`checkAuth` → `startpol`) and stop on `pause()`, logout, and
  `deinit`. `startpol` is idempotent.

## Serialization (`Lane`)

`save()` and every reconcile are read–compare–write sequences over two stores. Without ordering they would
race, for example: a pull reads the local sidecar, the user saves, then the pull's `copy` overwrites the
new edit. The `Lane` chains each operation onto the previous one's `Task`, so they run strictly in order,
one at a time.

```swift
lane.enqueue { … }                   // save, readiness reconcile: always runs
lane.enqueue(droppable: true) { … }  // poll tick: skipped if another droppable is pending
```

## Status and errors

`Synchronizer.description` combines the active provider's readiness description with the latest error
(`_error`). Errors come from `save`, `load`, `reconcile`, provider rotation, and the provider's
`strayError` (poll / monitor failures). The error is cleared when the approach changes.

## Known limitations

- **Concurrent edits lose data.** If two devices edit while out of sync, the later timestamp wins and the
  other edit is overwritten without a backup. This is a deliberate trade-off for simplicity.
- **Clock skew.** "Later" means each device's wall clock. A Mac with a fast clock wins conflicts it
  shouldn't.
- **Non-atomic remote pair.** The document and sidecar are uploaded separately. If the sidecar upload fails,
  other devices see no change; the next local-newer reconcile repairs it. If a reader downloads between
  the two uploads, it may see a new document with the old sidecar until the next tick.
- **One redundant push.** A poll tick that read the remote sidecar just before a `save()` push can push the
  same version again once. Harmless.
- **Poll cost.** Dropbox / Baidu Pan download the sidecar every 10 s while active.

## Testing

`StashTests/SynchronizerFakes.swift` provides `FakeLocal`, `FakeRemote` (seedable storage, injectable
errors, a `Gate` to pause downloads), `FakePoller`, and `SyncHarness` which wires a `Synchronizer` to fakes
with a temporary `History` file. `FakeRemote.tick()` simulates a poll tick.

`StashTests/SynchronizerTests.swift` covers every reconcile row and guard, the readiness trigger, approach
switching, save and offline recovery, `Lane` ordering and dropping, the polling loop (backoff, pause,
restart), `History`, and two-device convergence.

Run: `xcodebuild test -project Stash.xcodeproj -scheme Stash -destination 'platform=macOS' -only-testing:StashTests`
