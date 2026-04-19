' ============================================================
' ScreensaverScene.brs  -  BGViewer Dashboard (screensaver mode)
'
' Entry point used when Roku launches this channel as a screensaver
' (args.RunAsScreenSaver = true). No disclaimer, no settings UI.
' Account configuration is handled in the regular channel
' (MainScene); we read accounts from the shared registry.
'
' Roku dismisses the screensaver automatically on any key press,
' so this scene does not implement onKeyEvent.
'
' Dashboard rendering / fetching / parsing is provided by
' pkg:/source/Dashboard.brs.
' ============================================================

sub init()
    m.top.setFocus(true)

    wireDashboardNodes()
    dashboardSharedInit()

    ' Screensaver mode: no disclaimer, no settings - go straight to dashboard.
    m.inSettings   = false
    m.inDisclaimer = false

    startDashboardClock()

    ssLoadAndStart()
end sub

sub ssLoadAndStart()
    m.accounts    = loadAccounts()
    m.activeCount = countActive(m.accounts)

    if m.activeCount = 0
        ' Can't open settings from a screensaver. Just show a hint;
        ' user will dismiss with any key and configure in the channel.
        m.loadingMsg.text        = "Open Blood Glucose Viewer channel to configure accounts."
        m.loadingOverlay.visible = true
        return
    end if

    m.loadingOverlay.visible = false
    layoutCards()
    fetchAll()
end sub
