' ============================================================
' MainScene.brs  -  BGViewer Dashboard (channel mode)
'
' Channel-mode wrapper: disclaimer flow, settings UI, key handling.
' Dashboard rendering, fetching, and parsing live in
' pkg:/source/Dashboard.brs and are shared with ScreensaverScene.
' ============================================================

sub init()
    m.top.setFocus(true)

    ' Wire up dashboard nodes and shared state (defined in Dashboard.brs).
    wireDashboardNodes()
    dashboardSharedInit()

    m.settingsScene  = m.top.findNode("settingsScene")

    ' Channel-mode flags - the disclaimer/settings UIs only exist here.
    m.inSettings   = false
    m.inDisclaimer = true

    startDashboardClock()

    m.settingsScene.observeField("closed", "onSettingsClosed")
    m.settingsScene.observeField("needsFocus", "onSettingsNeedsFocus")

    ' Show disclaimer first; loadAndStart() called once user accepts
    m.disclaimerScene = m.top.findNode("disclaimerScene")
    m.disclaimerScene.observeField("accepted", "onDisclaimerAccepted")
    m.disclaimerScene.visible = true
    m.top.setFocus(true)
end sub

sub onDisclaimerAccepted()
    if not m.disclaimerScene.accepted then return
    m.disclaimerScene.visible = false
    m.inDisclaimer = false
    loadAndStart()
end sub

sub loadAndStart()
    m.accounts = loadAccounts()
    m.activeCount = countActive(m.accounts)
    if m.activeCount = 0
        openSettings()
    else
        m.loadingOverlay.visible = false
        layoutCards()
        fetchAll()
    end if
end sub

' ================================================================
' SETTINGS
' ================================================================

sub openSettings()
    m.inSettings = true
    m.clockTimer.control = "stop"
    m.settingsScene.visible = true
    m.loadingOverlay.visible = false
    m.top.setFocus(true)
end sub

sub onSettingsNeedsFocus()
    m.top.setFocus(true)
end sub

sub onSettingsClosed()
    if not m.settingsScene.closed then return
    m.settingsScene.visible = false
    m.settingsScene.closed  = false
    m.inSettings = false

    m.accounts    = loadAccounts()
    m.activeCount = countActive(m.accounts)

    if m.activeCount = 0
        m.loadingMsg.text        = "No accounts configured. Press OPTIONS to open settings."
        m.loadingOverlay.visible = true
    else
        m.loadingOverlay.visible = false
        layoutCards()
        m.results      = [invalid, invalid, invalid, invalid]
        m.histResults  = [invalid, invalid, invalid, invalid]
        m.deltaReady   = [false, false, false, false]
        m.dexSessions  = ["", "", "", ""]
        m.dexTicks     = [0, 0, 0, 0]
        m.secsLeft     = 0
        fetchAll()
    end if

    m.clockTimer.control = "start"
    m.top.setFocus(true)
end sub

' ================================================================
' KEY HANDLING
' ================================================================

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' Forward all keys to disclaimer until accepted
    if m.inDisclaimer
        if key = "OK" or key = "play" or key = "select"
            m.disclaimerScene.accepted = true
        end if
        return true
    end if

    if m.inSettings
        if key = "play"
            m.keySeqCounter = m.keySeqCounter + 1
            m.settingsScene.keyMsg = "closekeyboard:" + stri(m.keySeqCounter)
            return true
        end if
        m.keySeqCounter = m.keySeqCounter + 1
        m.settingsScene.keyMsg = key + ":" + stri(m.keySeqCounter)
        return true
    end if

    if key = "options"
        openSettings()
        return true
    end if
    if key = "back"
        m.top.close()
        return true
    end if
    return false
end function
