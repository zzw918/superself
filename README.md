# TodoListApp

A simple SwiftUI iOS app for 16:8 intermittent fasting and weight tracking.

## Features

- Track a 16-hour fasting window and an 8-hour eating window.
- See live countdown, progress ring, start time, and end time.
- Switch between fasting and eating phases.
- Reset the current phase when needed.
- Save the latest weight record.
- Keep a short daily fat-loss goal and habit checklist.

## Run

Open the project in Xcode:

```bash
open TodoListApp.xcodeproj
```

If `xcodebuild` reports that the active developer directory is Command Line Tools, switch it to Xcode first:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Then you can build from the command line:

```bash
xcodebuild -scheme TodoListApp -project TodoListApp.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```
