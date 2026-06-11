# SuperSelf

A simple SwiftUI iOS app for 16+8, 18+6, and 20+4 meal-timing plans with weight tracking.

## Features

- Choose 16+8, 18+6, or 20+4 plans.
- See live countdown, progress ring, start time, and end time.
- See today/yesterday/tomorrow labels for start and end times when a plan crosses midnight.
- Track plan history with start time, end time, target, duration, and completion status.
- Get a softer reminder before the target is reached, while still allowing manual early finish.
- Reset the current phase when needed.
- Save local weight history with optional notes.
- Sync fasting data and weight history with iCloud Key-Value Store when iCloud is enabled.
- Review and delete previous weight records.
- See a simple recent weight trend chart.
- Keep a short daily fat-loss goal and habit checklist.

## iCloud Sync

The app uses `NSUbiquitousKeyValueStore` for lightweight iCloud sync. It keeps local data available first, then syncs these values through iCloud when the app is properly signed:

- current plan, phase, and start time
- plan history
- latest weight
- weight history
- daily fat-loss goal

To enable real iCloud sync on a device:

1. Open `SuperSelf.xcodeproj` in Xcode.
2. Select the `SuperSelf` target.
3. Open `Signing & Capabilities`.
4. Choose your Apple Developer team.
5. Change the bundle identifier from `com.wayne.superself` to your own unique identifier if needed.
6. Add the `iCloud` capability.
7. Enable `Key-value storage`.
8. Run the app on devices signed with the same iCloud account.

Without the iCloud capability, the app still builds and saves data locally, but cross-device sync will not work.

## Run

Open the project in Xcode:

```bash
open SuperSelf.xcodeproj
```

If `xcodebuild` reports that the active developer directory is Command Line Tools, switch it to Xcode first:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Then you can build from the command line:

```bash
xcodebuild -scheme SuperSelf -project SuperSelf.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```
