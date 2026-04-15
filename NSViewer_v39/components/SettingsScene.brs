' SettingsScene.brs
' Two views: TABLE and EDIT.
' Edit view has conditional fields depending on source type (ns/dx).

sub init()
    ' Table nodes
    m.rowBgs   = [m.top.findNode("rowBg0"),   m.top.findNode("rowBg1"),   m.top.findNode("rowBg2"),   m.top.findNode("rowBg3")]
    m.nameTxts = [m.top.findNode("nameTxt0"), m.top.findNode("nameTxt1"), m.top.findNode("nameTxt2"), m.top.findNode("nameTxt3")]
    m.srcTxts  = [m.top.findNode("srcTxt0"),  m.top.findNode("srcTxt1"),  m.top.findNode("srcTxt2"),  m.top.findNode("srcTxt3")]
    m.urlTxts  = [m.top.findNode("urlTxt0"),  m.top.findNode("urlTxt1"),  m.top.findNode("urlTxt2"),  m.top.findNode("urlTxt3")]
    m.cursor   = m.top.findNode("cursor")
    m.statusMsg = m.top.findNode("statusMsg")

    m.tableNodes = [
        m.top.findNode("tblSubtitle"),
        m.top.findNode("tblColNum"), m.top.findNode("tblColName"), m.top.findNode("tblColSrc"), m.top.findNode("tblColVal"),
        m.top.findNode("tblDivTop"),
        m.top.findNode("rowBg0"), m.top.findNode("rowNum0"), m.top.findNode("nameTxt0"), m.top.findNode("srcTxt0"), m.top.findNode("urlTxt0"),
        m.top.findNode("rowBg1"), m.top.findNode("rowNum1"), m.top.findNode("nameTxt1"), m.top.findNode("srcTxt1"), m.top.findNode("urlTxt1"),
        m.top.findNode("rowBg2"), m.top.findNode("rowNum2"), m.top.findNode("nameTxt2"), m.top.findNode("srcTxt2"), m.top.findNode("urlTxt2"),
        m.top.findNode("rowBg3"), m.top.findNode("rowNum3"), m.top.findNode("nameTxt3"), m.top.findNode("srcTxt3"), m.top.findNode("urlTxt3"),
        m.top.findNode("cursor"),
        m.top.findNode("tblDivBot"), m.top.findNode("tblHint")
    ]

    ' Edit nodes shared
    m.dlgTitle   = m.top.findNode("dlgTitle")
    m.dlgNameBox = m.top.findNode("dlgNameBox")
    m.dlgNameTxt = m.top.findNode("dlgNameTxt")
    m.dlgSrcBox  = m.top.findNode("dlgSrcBox")
    m.dlgSrcTxt  = m.top.findNode("dlgSrcTxt")
    m.dlgHint    = m.top.findNode("dlgHint")
    ' NS fields
    m.dlgUrlBox  = m.top.findNode("dlgUrlBox")
    m.dlgUrlTxt  = m.top.findNode("dlgUrlTxt")
    ' Dexcom fields
    m.dlgUserBox = m.top.findNode("dlgUserBox")
    m.dlgUserTxt = m.top.findNode("dlgUserTxt")
    m.dlgPassBox = m.top.findNode("dlgPassBox")
    m.dlgPassTxt = m.top.findNode("dlgPassTxt")
    m.dlgRegBox  = m.top.findNode("dlgRegBox")
    m.dlgRegTxt  = m.top.findNode("dlgRegTxt")

    ' All edit-panel nodes for bulk show/hide
    m.editNodes = [
        m.top.findNode("dlgAccent"), m.top.findNode("dlgTitle"),
        m.top.findNode("dlgNameLbl"), m.top.findNode("dlgNameBox"), m.top.findNode("dlgNameTxt"),
        m.top.findNode("dlgSrcLbl"),  m.top.findNode("dlgSrcBox"),  m.top.findNode("dlgSrcTxt"), m.top.findNode("dlgSrcHint"),
        m.top.findNode("dlgUrlLbl"),  m.top.findNode("dlgUrlBox"),  m.top.findNode("dlgUrlTxt"),
        m.top.findNode("dlgUserLbl"), m.top.findNode("dlgUserBox"), m.top.findNode("dlgUserTxt"),
        m.top.findNode("dlgPassLbl"), m.top.findNode("dlgPassBox"), m.top.findNode("dlgPassTxt"),
        m.top.findNode("dlgRegLbl"),  m.top.findNode("dlgRegBox"),  m.top.findNode("dlgRegTxt"), m.top.findNode("dlgRegHint"),
        m.top.findNode("dlgHint")
    ]

    ' NS-only nodes
    m.nsNodes = [
        m.top.findNode("dlgUrlLbl"), m.top.findNode("dlgUrlBox"), m.top.findNode("dlgUrlTxt")
    ]
    ' Dexcom-only nodes
    m.dxNodes = [
        m.top.findNode("dlgUserLbl"), m.top.findNode("dlgUserBox"), m.top.findNode("dlgUserTxt"),
        m.top.findNode("dlgPassLbl"), m.top.findNode("dlgPassBox"), m.top.findNode("dlgPassTxt"),
        m.top.findNode("dlgRegLbl"),  m.top.findNode("dlgRegBox"),  m.top.findNode("dlgRegTxt"), m.top.findNode("dlgRegHint")
    ]

    m.keyboard  = invalid
    m.selRow    = 0
    m.dlgOpen   = false
    m.dlgField  = 0
    m.kbOpen    = false
    m.ROW_Y     = [152, 244, 336, 428]
    m.REGIONS   = ["us", "ous", "jp"]
    m.REGION_LABELS = ["US", "Outside US", "Japan"]

    m.accounts = loadAccounts()
    populateTable()
    updateCursor()
    showTableView()
    m.top.observeField("keyMsg", "onKeyPress")
end sub

' Returns max dlgField index for current account source type
function maxField() as Integer
    if m.accounts[m.selRow].srcType = "dx" then return 4
    return 2
end function

sub showTableView()
    for each node in m.tableNodes
        node.visible = true
    end for
    for each node in m.editNodes
        node.visible = false
    end for
end sub

sub showEditView()
    for each node in m.tableNodes
        node.visible = false
    end for
    for each node in m.editNodes
        node.visible = true
    end for
    ' Show only the source-appropriate field set
    applySourceVisibility()
end sub

sub applySourceVisibility()
    isDex = (m.accounts[m.selRow].srcType = "dx")
    for each node in m.nsNodes
        node.visible = not isDex
    end for
    for each node in m.dxNodes
        node.visible = isDex
    end for
    ' Update hint text
    if isDex
        m.dlgHint.text = "UP/DOWN = field   LEFT/RIGHT = toggle region   OK = type   PLAY = done   OPTIONS = save"
    else
        m.dlgHint.text = "UP/DOWN = field   LEFT/RIGHT = switch source   OK = type   PLAY = done   OPTIONS = save"
    end if
end sub

sub populateTable()
    for i = 0 to 3
        acct = m.accounts[i]
        m.nameTxts[i].text = acct.name
        if acct.srcType = "dx"
            m.srcTxts[i].text = "Dexcom"
            m.urlTxts[i].text = acct.dexUser
        else
            m.srcTxts[i].text = "NS"
            m.urlTxts[i].text = truncStr(acct.url, 60)
        end if
    end for
end sub

function truncStr(s as String, n as Integer) as String
    if Len(s) <= n then return s
    return Mid(s, 1, n - 3) + "..."
end function

sub updateCursor()
    m.cursor.translation = [60, m.ROW_Y[m.selRow]]
    for i = 0 to 3
        m.rowBgs[i].color = "#0D0D0D"
    end for
    m.rowBgs[m.selRow].color = "#001830"
end sub

sub openDialog()
    m.dlgOpen  = true
    m.dlgField = 0
    m.dlgTitle.text = "EDITING ACCOUNT " + Mid(stri(m.selRow + 1), 2)
    updateDialogFields()
    updateDialogCursor()
    showEditView()
end sub

sub closeDialog()
    m.dlgOpen = false
    closeKeyboardSilent()
    populateTable()
    showTableView()
end sub

sub updateDialogFields()
    acct = m.accounts[m.selRow]
    m.dlgNameTxt.text = acct.name
    if acct.srcType = "dx"
        m.dlgSrcTxt.text  = "Dexcom Share"
        m.dlgUserTxt.text = acct.dexUser
        ' Show password masked
        if acct.dexPass = ""
            m.dlgPassTxt.text = ""
        else
            m.dlgPassTxt.text = "(set)"
        end if
        m.dlgRegTxt.text = regionLabel(acct.dexRegion)
    else
        m.dlgSrcTxt.text = "Nightscout"
        url = acct.url
        if url = "" then url = "https://"
        m.dlgUrlTxt.text = url
    end if
end sub

function regionLabel(r as String) as String
    if r = "ous" then return "Outside US"
    if r = "jp"  then return "Japan"
    return "US"
end function

sub updateDialogCursor()
    ' Reset all boxes
    m.dlgNameBox.color = "#1A1A1A"
    m.dlgSrcBox.color  = "#1A1A1A"
    m.dlgUrlBox.color  = "#1A1A1A"
    m.dlgUserBox.color = "#1A1A1A"
    m.dlgPassBox.color = "#1A1A1A"
    m.dlgRegBox.color  = "#1A1A1A"
    ' Highlight active field
    isDex = (m.accounts[m.selRow].srcType = "dx")
    if m.dlgField = 0
        m.dlgNameBox.color = "#003366"
    else if m.dlgField = 1
        m.dlgSrcBox.color  = "#003366"
    else if m.dlgField = 2
        if isDex
            m.dlgUserBox.color = "#003366"
        else
            m.dlgUrlBox.color  = "#003366"
        end if
    else if m.dlgField = 3
        m.dlgPassBox.color = "#003366"
    else if m.dlgField = 4
        m.dlgRegBox.color  = "#003366"
    end if
end sub

sub openKeyboard()
    closeKeyboardSilent()
    ' Region and source type are toggled with left/right, not typed - skip keyboard for those
    if m.dlgField = 1 or m.dlgField = 4 then return

    m.keyboard = m.top.createChild("Keyboard")
    m.keyboard.translation = [60, 490]
    m.keyboard.observeField("text", "onKeyboardText")

    acct = m.accounts[m.selRow]
    if m.dlgField = 0
        m.keyboard.text = acct.name
    else if m.dlgField = 2
        if acct.srcType = "dx"
            m.keyboard.text = acct.dexUser
        else
            url = acct.url
            if url = "" then url = "https://"
            m.keyboard.text = url
        end if
    else if m.dlgField = 3
        m.keyboard.text = acct.dexPass
    end if

    m.kbOpen = true
    m.keyboard.setFocus(true)
end sub

sub closeKeyboardSilent()
    m.kbOpen = false
    if m.keyboard <> invalid
        m.keyboard.visible = false
        m.top.removeChild(m.keyboard)
        m.keyboard = invalid
    end if
end sub

sub closeKeyboardAndReturn()
    closeKeyboardSilent()
    ' Sanitise NS URL
    acct = m.accounts[m.selRow]
    if m.dlgField = 2 and acct.srcType = "ns"
        url = acct.url
        if url = "https://" or url = "http://"
            acct.url = ""
        else if url <> "" and Mid(url, 1, 4) <> "http"
            acct.url = "https://" + url
        end if
        m.accounts[m.selRow] = acct
    end if
    updateDialogFields()
    m.top.needsFocus = m.top.needsFocus + 1
end sub

sub onKeyboardText()
    if not m.kbOpen then return
    val  = m.keyboard.text
    acct = m.accounts[m.selRow]
    if m.dlgField = 0
        acct.name = val
    else if m.dlgField = 2
        if acct.srcType = "dx"
            acct.dexUser = val
        else
            acct.url = val
        end if
    else if m.dlgField = 3
        acct.dexPass = val
    end if
    m.accounts[m.selRow] = acct
end sub

sub toggleSource()
    acct = m.accounts[m.selRow]
    if acct.srcType = "dx"
        acct.srcType = "ns"
    else
        acct.srcType = "dx"
    end if
    m.accounts[m.selRow] = acct
    ' If source changed, reset dlgField to avoid being on a field that doesn't exist
    m.dlgField = 1
    updateDialogFields()
    updateDialogCursor()
    applySourceVisibility()
end sub

sub cycleRegion(dir as Integer)
    acct = m.accounts[m.selRow]
    curIdx = 0
    for i = 0 to 2
        if m.REGIONS[i] = acct.dexRegion then curIdx = i
    end for
    curIdx = (curIdx + dir + 3) mod 3
    acct.dexRegion = m.REGIONS[curIdx]
    m.accounts[m.selRow] = acct
    m.dlgRegTxt.text = m.REGION_LABELS[curIdx]
end sub

sub doSave()
    saveAccounts(m.accounts)
    m.statusMsg.text  = "Saved!"
    m.statusMsg.color = "#00C853"
    m.saveTimer = CreateObject("roSGNode", "Timer")
    m.saveTimer.duration = 2
    m.saveTimer.repeat   = false
    m.saveTimer.observeField("fire", "onSaveTimerDone")
    m.saveTimer.control  = "start"
end sub

sub onSaveTimerDone()
    m.top.saved  = true
    m.top.closed = true
end sub

sub onKeyPress()
    msg = m.top.keyMsg
    if msg = "" then return
    colonPos = Instr(1, msg, ":")
    key = msg
    if colonPos > 1 then key = Mid(msg, 1, colonPos - 1)

    if key = "closekeyboard"
        if m.kbOpen then closeKeyboardAndReturn()
        return
    end if

    if m.kbOpen then return

    if m.dlgOpen
        if key = "up"
            if m.dlgField > 0
                m.dlgField = m.dlgField - 1
                updateDialogCursor()
            end if
        else if key = "down"
            if m.dlgField < maxField()
                m.dlgField = m.dlgField + 1
                updateDialogCursor()
            end if
        else if key = "left" or key = "right"
            if m.dlgField = 1
                toggleSource()
            else if m.dlgField = 4
                if key = "right"
                    cycleRegion(1)
                else
                    cycleRegion(-1)
                end if
            end if
        else if key = "OK"
            openKeyboard()
        else if key = "options"
            doSave()
        else if key = "back"
            closeDialog()
        end if
        return
    end if

    if key = "up"
        if m.selRow > 0
            m.selRow = m.selRow - 1
            updateCursor()
        end if
    else if key = "down"
        if m.selRow < 3
            m.selRow = m.selRow + 1
            updateCursor()
        end if
    else if key = "OK"
        openDialog()
    else if key = "options"
        doSave()
    else if key = "back"
        m.top.closed = true
    end if
end sub
