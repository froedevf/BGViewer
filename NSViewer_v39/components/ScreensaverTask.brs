' ScreensaverTask.brs
' Previously suppressed the screensaver via UpdateLastKeyPressTime().
' That API is no longer permitted; the task is retained as a no-op
' so the rest of the channel does not need to be restructured.

sub init()
    m.top.functionName = "run"
end sub

sub run()
    ' UpdateLastKeyPressTime() is a banned API - screensaver suppression removed.
end sub
