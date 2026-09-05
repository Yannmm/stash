# Nustash

**Nustash** is a macOS menu-bar bookmark manager designed to make your bookmarks fast to access, easy to organize, and available across devices.

It lives quietly in the macOS menu bar and gives you a quick way to **manage, search, and launch bookmarks** without keeping a traditional bookmark-management window open all the time.

Nustash supports different kinds of bookmarks, hierarchical groups, hashtags, global keyboard shortcuts, browser-specific launching, and multiple synchronization backends.

---

## Features

### 🧭 Menu-bar bookmark manager

Nustash runs primarily as a **menu-bar application** rather than a traditional Dock application.

From the menu bar you can:

* Browse your bookmark hierarchy
* Open bookmarks quickly
* Access recently visited bookmarks
* Search bookmarks
* Navigate groups
* Launch bookmarks using the keyboard
* Open the full bookmark manager when you need more control

The application normally runs as a macOS accessory app and only becomes a regular foreground application when a management or settings window is opened.

---

### 🔎 Fast search

Nustash provides a dedicated search interface for quickly finding bookmarks and groups.

Search supports:

* Bookmark titles
* Bookmark URLs
* Groups
* Hierarchical navigation
* Keyboard navigation
* `↑` / `↓` selection
* `Enter` to open the selected item
* Navigation into groups and back to the parent level

The search interface can be opened through a configurable **global keyboard shortcut**, allowing bookmarks to be accessed without first opening the menu-bar menu.

---

### 🗂 Hierarchical organization

Bookmarks can be organized into nested groups.

For example:

```text
Development
├── Apple
│   ├── Swift
│   ├── SwiftUI
│   └── AppKit
├── Flutter
│   ├── Flutter Docs
│   └── Flutter Packages
└── GitHub

AWS
├── Documentation
├── Console
└── Architecture

Reading
├── Articles
└── Books
```

Groups and bookmarks share a common `Entry` model, allowing the application to treat them uniformly for navigation, searching, dragging, and organization.

The management interface supports:

* Creating groups
* Editing entries
* Moving entries
* Reordering entries
* Nested groups
* Drag-and-drop organization
* Expanding and collapsing groups
* Moving children between hierarchy levels

---

### #️⃣ Hashtags

Bookmarks and groups can have hashtags.

Hashtags provide another way to organize and identify bookmarks without changing their hierarchy.

For example:

```text
#swift
#flutter
#aws
#work
#reading
```

Hashtags can also influence how a bookmark is opened.

For example, Nustash can interpret browser-related hashtags and use the specified browser when launching a bookmark.

---

### 🌐 Open with a specific browser

Bookmarks can normally be opened using the system's preferred application.

Nustash also supports browser-specific launching through hashtags.

This makes it possible to keep a bookmark in Nustash while controlling which browser should open it.

This is particularly useful when you use different browsers for different purposes, such as:

```text
#Safari
#Chrome
#Firefox
#Edge
```

---

### 🕘 Recently visited bookmarks

Nustash keeps track of recently opened bookmarks and exposes them directly from the menu.

Recent bookmarks are assigned keyboard shortcuts so they can be accessed quickly from the menu-bar interface.

The recent-history section can also be collapsed or hidden through Settings.

---

## Synchronization

Nustash separates its synchronization mechanism from the bookmark-management logic through a provider-based synchronization architecture.

The following synchronization approaches are currently implemented:

| Provider      | Description                            |
| ------------- | -------------------------------------- |
| **Local**     | Store bookmark data locally on the Mac |
| **iCloud**    | Synchronize through iCloud             |
| **Dropbox**   | Synchronize through Dropbox            |
| **Baidu Pan** | Synchronize through Baidu Netdisk      |

The synchronization provider can be selected from:

**Settings → Synchronization**

### Local storage

The default local provider stores Nustash's bookmark document and synchronization metadata inside the user's macOS Application Support directory.

The bookmark document is stored as:

```text
nustash_index.html
```

with synchronization metadata stored alongside it:

```text
nustash_index.html.sidecar.json
```

### iCloud

The iCloud provider stores the same document and sidecar files in the application's iCloud container.

Nustash monitors changes to the iCloud files so changes made outside the application can be detected and loaded.

### Dropbox

Dropbox synchronization uses OAuth authentication and stores the Nustash document in the application's Dropbox area.

### Baidu Pan

Baidu Pan synchronization also uses OAuth authentication and stores Nustash's synchronization files under:

```text
/apps/Nustash/
```

Authentication credentials are stored using the macOS Keychain.

---

## Import

Nustash can import bookmarks from several existing bookmark-management formats.

### Browser bookmarks

Nustash supports the **Netscape Bookmark File** format used by major browsers.

Import is supported for bookmarks exported from:

* Google Chrome
* Microsoft Edge
* Mozilla Firefox
* Safari

The browser bookmark file is parsed and converted into Nustash's internal hierarchy.

When importing, you can choose whether to:

* **Replace** the current bookmark collection
* **Add** the imported bookmarks as a new group

When adding bookmarks, Nustash handles ID conflicts between the imported data and existing bookmarks.

---

### Pocket

Nustash can import bookmarks from a Pocket CSV export.

Pocket tags are converted into Nustash hashtags.

---

### Hungrymarks

Nustash supports importing the text-based **Hungrymarks** format, including its hierarchical directory structure.

---

## Export

Nustash exports bookmarks using the **Netscape Bookmark File** format.

This makes exported bookmark data compatible with common browser bookmark import tools.

Exports can be saved to a directory selected by the user.

Before destructive operations such as resetting the bookmark database, Nustash can also create a backup export.

---

## Data model

Nustash uses a small, hierarchy-oriented data model.

At the core is the `Entry` protocol.

An entry contains:

* A unique identifier
* A name
* A parent identifier
* An icon
* Optional hashtags
* Container information

There are currently two primary entry types:

### Bookmark

A bookmark contains:

```text
ID
Name
Parent
URL
Hashtags
```

Bookmarks can represent:

* Web URLs
* Local files
* Other URL schemes such as VNC

### Group

A group is a container for other entries:

```text
ID
Name
Parent
Hashtags
```

This allows Nustash to represent an arbitrary nested bookmark hierarchy.

---

## Keyboard-first workflow

Nustash is designed to work well without constantly reaching for the mouse.

Configurable global shortcuts are available for:

* Opening the Nustash menu
* Opening search

Within search and management views, keyboard navigation can be used to move through entries and perform actions.

The application also remembers relevant search and interaction state to make repeated bookmark access faster.

---

## Management window

When you need more than the compact menu-bar interface provides, Nustash includes a dedicated bookmark-management window.

The management UI uses a two-pane layout:

```text
┌──────────────────┬─────────────────────────────────────┐
│                  │                                     │
│    Collections   │              Workbench              │
│                  │                                     │
│    ∞ Root        │  Bookmark 1                         │
│    Development   │  Bookmark 2                         │
│      Swift       │  Bookmark 3                         │
│      Flutter     │                                     │
│    Reading       │  ...                                │
│                  │                                     │
└──────────────────┴─────────────────────────────────────┘
```

The sidebar represents the bookmark hierarchy, while the workbench displays and manages entries within the selected collection.

The workbench includes:

* Search
* Hierarchy navigation
* Bookmark counts
* Group counts
* Hashtag filtering
* Drag-and-drop
* Reordering
* Keyboard navigation
* Inline editing
* Context menus
* Bookmark preview/opening

---

## Settings

Nustash provides settings for:

### General

* Launch on Login
* Global application shortcut
* Global search shortcut
* Recent-bookmark history visibility

### Synchronization

Select between:

* Local
* iCloud
* Dropbox
* Baidu Pan

### Data Management

* Import bookmarks
* Export bookmarks
* Reset all data

### Software Update

Nustash checks the App Store for newer versions and can direct the user to the latest release.

---

## Architecture

Nustash is a native macOS application written in **Swift** using **SwiftUI** and **AppKit**.

The application follows a lightweight separation between:

```text
UI
 │
 ├── SwiftUI Views
 │
 └── View Models
       │
       ▼
   Housekeeper
       │
       ▼
  Synchronizer
       │
       ├── Local Provider
       ├── iCloud Provider
       ├── Dropbox Provider
       └── Baidu Pan Provider
```

### AppDelegate

`AppDelegate` owns the macOS application lifecycle and the menu-bar integration.

It manages:

* `NSStatusItem`
* Menu-bar interactions
* Search panels
* Settings window
* Management window
* Global shortcut notifications
* URL scheme events
* Application activation state
* Update checking

### Housekeeper

`Housekeeper` is responsible for the application's bookmark collection.

It handles:

* Loading entries
* Saving entries
* Adding/updating entries
* Deleting entries
* Moving entries
* Recent history
* Import
* Export
* Resetting the collection

### Synchronizer

`Synchronizer` abstracts where bookmark data is stored.

Providers conform to a common interface so the rest of the application does not need to know whether the data lives locally, in iCloud, Dropbox, or Baidu Pan.

This makes the synchronization layer extensible without coupling the bookmark model to a particular cloud service.

---

## Technology

Nustash is built with native Apple technologies and several Swift packages.

### Apple frameworks

* SwiftUI
* AppKit
* Foundation
* Combine
* UniformTypeIdentifiers
* Security
* ServiceManagement
* CryptoKit
* CommonCrypto

### Swift packages

The project currently uses libraries including:

* **HotKey** — global keyboard shortcuts
* **Kingfisher** — image/favicon loading
* **OrderedCollections** — ordered hashtag collections
* **CombineExt** — additional Combine operators
* **SwiftSoup** — HTML/bookmark document parsing
* **SwiftyDropbox** — Dropbox integration
* **CodableCSV** — Pocket CSV parsing

---

## URL schemes

Nustash registers its own URL scheme:

```text
nustash://
```

This allows external events to communicate with the application.

The application also registers the Dropbox OAuth callback scheme required for Dropbox authentication.

---

## Requirements

* macOS
* Xcode
* Swift
* A Mac capable of running the supported macOS version

Nustash is a native macOS application and does not require a separate runtime such as Electron, Python, or Node.js.

---

## Development

Clone the repository:

```bash
git clone https://github.com/Yannmm/stash.git
cd stash
```

Then open the project in Xcode and build/run the application.

> The project is currently named `Stash` internally in several source files, while the user-facing application is **Nustash**.

---

## Project structure

```text
Stash/
├── Models/
│   ├── Bookmark.swift
│   ├── Group.swift
│   ├── Entry.swift
│   ├── AnyEntry.swift
│   ├── Hashtag.swift
│   └── Icon.swift
│
├── ViewModels/
│   ├── HouseKeeper.swift
│   ├── SearchViewModel.swift
│   ├── WorkbenchViewModel.swift
│   ├── SettingsViewModel.swift
│   ├── SidebarViewModel.swift
│   └── ...
│
├── Views/
│   ├── Manage/
│   ├── Settings/
│   └── Components/
│
├── Synchronization/
│   ├── Synchronizer.swift
│   ├── Provider.swift
│   ├── OnPremiseProvider.swift
│   ├── AiCloudProvider.swift
│   ├── DropboxProvider.swift
│   ├── BaiduPanProvider.swift
│   ├── Sidecar.swift
│   └── SyncHistory.swift
│
├── Helpers/
│   ├── HotKeyManager.swift
│   ├── CsvParser.swift
│   ├── HungryMarkParser.swift
│   ├── UpdateChecker.swift
│   └── ...
│
├── Extensions/
└── AppDelegate.swift
```

---

## Philosophy

Nustash is built around a simple idea:

> **Your bookmarks should be available when you need them, without getting in your way.**

Instead of treating bookmarks as something that only belongs inside a web browser, Nustash treats them as a lightweight collection of things you want to quickly access from your Mac.

A bookmark can point to a website, a local file, a remote resource, or another useful URL. Groups provide hierarchy, hashtags provide flexible organization, and the menu-bar interface keeps everything only a shortcut away.

---

## Status

Nustash is an actively developed open-source macOS application.

The project continues to evolve around:

* Faster bookmark access
* Better search
* Improved organization
* Synchronization reliability
* Keyboard-driven workflows
* Native macOS interaction

---

## Feedback & Issues

Nustash is open source.

Bug reports, feature requests, and feedback are welcome through GitHub Issues.

**Repository:**
https://github.com/Yannmm/stash

**Issues:**
https://github.com/Yannmm/stash/issues

---

## License

Nustash is free and open-source software licensed under the **GNU General Public License v3.0**.

You are free to:

* Use Nustash for any purpose
* Study how Nustash works
* Modify the source code
* Redistribute original or modified versions

Any distributed modified version must also be licensed under the GPLv3 and provide the corresponding source code in accordance with the license.

See the [`LICENSE`](LICENSE) file for the complete license text.

**SPDX-License-Identifier:** `GPL-3.0-only`

