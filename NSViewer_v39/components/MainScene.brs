' ============================================================
' MainScene.brs  -  BGViewer (setup-only channel shell)
'
' BGViewer's data display lives entirely in the registered
' screensaver (ScreensaverScene). This channel scene is only
' used to:
'
'   1. Show the medical disclaimer (on launch).
'   2. Let the user configure Nightscout / Dexcom accounts.
'   3. Show a "Setup Complete" screen explaining how to enable
'      the screensaver in Roku's settings.
'
' Accounts are persisted in the shared roRegistrySection(
' "nightscout") by SettingsScene (via RegistryUtils.brs) and
' read back by ScreensaverScene when the screensaver launches.
' ============================================================

sub init()
    m.top.setFocus(true)

    m.bg              = m.top.findNode("bg")
    m.hdrSubtitle     = m.top.findNode("hdrSubtitle")
    m.statusLabel     = m.top.findNode("statusLabel")

    m.disclaimerScene = m.top.findNode("disclaimerScene")
    m.settingsScene   = m.top.findNode("settingsScene")

    m.setupPanel      = m.top.findNode("setupPanel")
    m.setupSummary    = m.top.findNode("setupSummary")
    m.accountsTitle   = m.top.findNode("accountsTitle")
    m.accountsList    = m.top.findNode("accountsList")

    m.noAcctPanel     = m.top.findNode("noAcctPanel")

    m.keySeqCounter   = 0

    ' Disclaimer is always shown first.
    m.inDisclaimer = true
    m.inSettings   = false

    m.disclaimerScene.observeField("accepted",   "onDisclaimerAccepted")
    m.settingsScene.observeField("closed",       "onSettingsClosed")
    m.settingsScene.observeField("needsFocus",   "onSettingsNeedsFocus")

    m.disclaimerScene.visible = true
    m.setupPanel.visible      = false
    m.noAcctPanel.visible     = false
    m.settingsScene.visible   = false

    m.top.setFocus(true)
end sub

' ================================================================
' DISCLAIMER
' ================================================================

sub onDisclaimerAccepted()
    if not m.disclaimerScene.accepted then return
    m.disclaimerScene.visible = false
    m.inDisclaimer = false
    routeAfterConfigChange()
end sub

' ================================================================
' SETTINGS
' ================================================================

sub openSettings()
    m.inSettings = true
    m.setupPanel.visible    = false
    m.noAcctPanel.visible   = false
    m.settingsScene.visible = true
    if m.hdrSubtitle <> invalid then m.hdrSubtitle.text = "SETTINGS"
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
    routeAfterConfigChange()
end sub

' ================================================================
' POST-CONFIG ROUTING
' After the disclaimer is accepted or settings close, decide
' which setup screen to show.
' ================================================================

sub routeAfterConfigChange()
    accounts = loadAccounts()
    activeCount = 0
    for i = 0 to 3
        if isAccountActive(accounts[i]) then activeCount = activeCount + 1
    end for

    if activeCount = 0
        showNoAccounts()
    else
        showSetupComplete(accounts, activeCount)
    end if
end sub

sub showNoAccounts()
    m.setupPanel.visible  = false
    m.noAcctPanel.visible = true
    if m.hdrSubtitle <> invalid then m.hdrSubtitle.text = "SETUP"
    if m.statusLabel <> invalid then m.statusLabel.text = ""
    m.top.setFocus(true)
end sub

sub showSetupComplete(accounts as Object, activeCount as Integer)
    m.noAcctPanel.visible = false
    m.setupPanel.visible  = true

    if m.hdrSubtitle <> invalid then m.hdrSubtitle.text = "SETUP COMPLETE"

    ' Summary line
    if activeCount = 1
        m.setupSummary.text = "You have 1 account configured. It will be displayed on your screensaver."
    else
        m.setupSummary.text = "You have " + stri(activeCount).Trim() + " accounts configured. They will be displayed on your screensaver."
    end if

    ' Accounts list
    lines = []
    for i = 0 to 3
        acct = accounts[i]
        if isAccountActive(acct)
            label = acct.name
            if label = "" then label = "Account " + stri(i + 1).Trim()
            if acct.srcType = "dx"
                src = "Dexcom (" + acct.dexRegion.ToUpper() + ")"
            else
                src = "Nightscout"
            end if
            lines.push(chr(8226) + "  " + label + "   -   " + src)
        end if
    end for

    if lines.Count() > 0
        m.accountsTitle.visible = true
        m.accountsList.visible  = true
        joined = ""
        for i = 0 to lines.Count() - 1
            if i > 0 then joined = joined + chr(10)
            joined = joined + lines[i]
        end for
        m.accountsList.text = joined
    else
        m.accountsTitle.visible = false
        m.accountsList.visible  = false
        m.accountsList.text     = ""
    end if

    if m.statusLabel <> invalid then m.statusLabel.text = ""
    m.top.setFocus(true)
end sub

' ================================================================
' KEY HANDLING
' ================================================================

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

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
