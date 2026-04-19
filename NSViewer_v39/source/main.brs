' ============================================================
' main.brs  -  BGViewer (Blood Glucose Viewer)
'
' Two entry modes:
'   - Normal channel launch  -> MainScene (setup only: disclaimer
'                               + account configuration; no data
'                               display).
'   - Screensaver launch     -> ScreensaverScene (the dashboard;
'                               this is the only place glucose
'                               data is rendered).
'
' Roku passes args.RunAsScreenSaver = true when the OS is launching
' this channel as the active screensaver.
' ============================================================
sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    isScreensaver = false
    if args <> invalid and type(args) = "roAssociativeArray"
        if args.RunAsScreenSaver <> invalid and args.RunAsScreenSaver = true
            isScreensaver = true
        end if
    end if

    if isScreensaver
        scene = screen.CreateScene("ScreensaverScene")
    else
        scene = screen.CreateScene("MainScene")
    end if

    screen.show()
    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
end sub
