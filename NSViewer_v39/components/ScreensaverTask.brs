' ScreensaverTask.brs
' Pings roAppManager every 30s to suppress the screensaver.
' Must run in a Task node - roAppManager fails on render thread.

sub init()
    m.top.functionName = "run"
end sub

sub run()
    appManager = CreateObject("roAppManager")
    if appManager = invalid then return
    msgPort = CreateObject("roMessagePort")
    while true
        appManager.UpdateLastKeyPressTime()
        wait(30000, msgPort)
    end while
end sub
