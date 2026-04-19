# BGViewer - Roku Partner Portal Resubmission Checklist

## Summary of changes since last submission

This build corrects the root cause of cert violation **4.5** ("Channels
are prohibited from offering in-channel screensavers or any feature that
overrides the Roku system screensaver"):

1. Removed `screensaver_private=1` from the manifest. That key declared
   this package as an **in-channel** screensaver (one that runs only
   while the channel is open, and does not appear in Roku's system
   screensaver list). That is literally the behavior rule 4.5 prohibits.
2. The package is now a **public screensaver**, selectable from
   `Settings > Screensaver > Change screensaver` on the user's Roku.
3. The channel shell (`MainScene`) is configuration-only: medical
   disclaimer + account editor + a "Setup Complete" screen that points
   the user at the Screensaver setting. No dashboard runs in the
   channel.
4. Dashboard rendering lives exclusively in `ScreensaverScene`, which
   Roku launches with `args.RunAsScreenSaver = true`.

## Partner Portal settings to verify on resubmission

When you upload this build to the Roku Partner Portal, make sure:

- **Channel Type** is set to **Screensaver** (NOT *Streaming Channel*).
  Submitting a screensaver package under the "Channel" type triggers a
  "Channel type is channel" validation error and invites rule 4.5
  reviews against a streaming-channel rubric.
- The listing category is **Screensavers**.
- The screenshot / preview assets depict the screensaver view (the
  four-card dashboard) rather than the setup shell.

## Manifest sanity check

Confirm the manifest does NOT contain:
- `screensaver_private=1`  (re-adding this would re-trigger 4.5)
- Any `Video` node in `MainScene`, `ScreensaverScene`, or tasks
- Any `Audio`/`Sound` node, or looping audio
- `video/keepalive.mp4` (deleted in build 1.1.00003)
- `audio/silence.wav` (deleted in build 1.2.00003)
- `components/ScreensaverTask.{brs,xml}` (deleted in build 1.1.00003)

## Version history of cert-related changes

- 1.1.00003 - Removed keepalive video + no-op screensaver task.
- 1.2.00001 - Restructured so the channel is setup-only; all dashboard
  logic moved out of `MainScene` and into `ScreensaverScene`.
- 1.2.00002 - Removed `screensaver_private=1` from the manifest.
  Package now registers as a public screensaver.
- 1.2.00003 - Deleted orphaned `audio/silence.wav`. Silent audio
  played in a loop defeats the system screensaver the same way a
  keep-alive video does; the mere presence of this asset in the
  package invites a 4.5 flag even though nothing in the source
  referenced it.
