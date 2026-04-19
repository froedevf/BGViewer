' ============================================================
' ScreensaverScene.brs  -  BGViewer Dashboard
'
' This scene is BGViewer's only data display. It is rendered
' exclusively via the Roku screensaver lifecycle, when the OS
' launches this channel with args.RunAsScreenSaver = true.
'
' The BGViewer channel entry point (MainScene) is a setup-only
' shell: medical disclaimer + account configuration. It does
' not render glucose data.
'
' Roku dismisses the screensaver automatically on any key press,
' so this scene does not implement onKeyEvent. Accounts are read
' from roRegistrySection("nightscout") via RegistryUtils.brs;
' dashboard rendering / fetching / parsing lives in
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
