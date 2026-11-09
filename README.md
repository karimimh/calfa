# calfa

A small native macOS app, written in Swift and SwiftUI, that shows a month view of the Persian (Solar Hijri / Jalali) calendar with Persian labels.

The window title and UI text are in Persian ("تقویم شمسی" means "Solar calendar"). The project has no third-party dependencies and builds with the Swift Package Manager alone. You don't need an Xcode project.

## Features

- **Today's date in Persian.** The header shows the full current date (weekday, day, month name, year), formatted with Foundation's `Calendar(identifier: .persian)` and the `fa_IR` locale.
- **Month grid.** A 6 × 7 grid of days with Persian weekday initials (Saturday first). Days from the previous and next months are dimmed, and today is highlighted.
- **Navigation.** Buttons step to the previous or next month, and a "برو به امروز" ("go to today") button jumps back to the current month.
- **Custom Persian typeface.** At launch the app registers the Yekan Bakh *FaNum* font through Core Text if you place a licensed copy in `Resources/` (see "Third-party assets"). The FaNum variant draws digits as Persian numerals. Without the font file, SwiftUI falls back to the system font.
- **Native window behavior.** The window has a fixed 400 × 500 size and a frame autosave name, so macOS can restore its position between launches. The app quits when its window closes.

## Architecture

The app is a single executable SwiftPM target with three layers:

```
main.swift ── NSApplication + AppDelegate ── NSWindow ── NSHostingView(ContentView)
                                                             │
                     PersianCalendarViewModel (ObservableObject)
                       ├─ currentDate / calendarDays (@Published)
                       └─ generateCalendarDays() using Calendar(.persian)

FontExtension.swift ── FontManager (registers the optional TTF via CTFontManager)
                    └─ Font.yekanBakh(size:weight:) helper used by the views
```

- **App bootstrap.** `main.swift` starts `NSApplication` by hand and uses an `AppDelegate` to create the window. This lets the package ship as a plain executable instead of an Xcode app project.
- **View model.** `PersianCalendarViewModel` holds the month being shown. It builds the 42 `CalendarDay` cells from Foundation's Persian calendar and publishes them to the SwiftUI views (`ContentView`, `PersianCalendarGrid`, `DayView`).
- **Font loading.** `FontManager` finds the font in the package's resource bundle (`Bundle.module`) and registers it for the current process.

## Tech stack

- Swift (tools version 6.1), SwiftUI, AppKit
- Foundation `Calendar` / `DateFormatter` (Persian calendar, `fa_IR` locale)
- Core Text / Core Graphics for runtime font registration
- Swift Package Manager; macOS 13 Ventura or later

## Repository layout

```
.
├── Package.swift               # SwiftPM manifest: one executable target, macOS 13+
├── Sources/
│   ├── main.swift              # App entry point, window, SwiftUI views, calendar view model
│   └── FontExtension.swift     # Font helper and Core Text font registration
├── Resources/
│   └── README.md               # Where to put the optional licensed font (see "Third-party assets")
└── .vscode/launch.json         # Debug/Release launch configs for the VS Code Swift extension
```

## Getting started

### Requirements

- macOS 13 or later
- A Swift 6.1+ toolchain (Xcode 16.3+ or the matching Command Line Tools)

### Build and run

```bash
swift build                 # debug build in .build/
swift run calfa             # build and launch the app

swift build -c release      # optimized build
.build/release/calfa        # launch the release binary
```

To work in Xcode, open `Package.swift` and run the `calfa` scheme. In VS Code with the Swift extension, use the "Debug calfa" or "Release calfa" launch configurations.

## Configuration

There are no settings or environment variables. The only optional runtime input is a font file in `Resources/`, which SwiftPM copies into the `calfa_calfa` resource bundle at build time.

## Third-party assets

The app is designed around the Yekan Bakh FaNum typeface by Reza Bakhtiarifard and Mahan Jafarzadeh, © Fontiran ([fontiran.com](https://fontiran.com)). It is a commercial font, so it is **not included** in this repository. To use it, buy a license from Fontiran and save the file as `Resources/YekanBakhFaNum-Regular.ttf` (or `.otf`); the file is git-ignored. Without it, the app runs with the system font.

## Project status

This is a small personal project and an early prototype: it has two commits and no tests or packaged `.app` bundle. Known limitations:

- **One font weight.** Only the Regular weight is bundled, so the `weight` argument of `Font.yekanBakh` has no visible effect.
- **Grid direction.** The grid is laid out left to right rather than in a right-to-left Persian layout.

## License

Released under the [MIT License](LICENSE). The optional Yekan Bakh font is third-party and not covered by this license.
