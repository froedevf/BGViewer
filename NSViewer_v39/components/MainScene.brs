' ============================================================
' MainScene.brs  -  Nightscout Dashboard
' ============================================================

sub init()
    m.top.setFocus(true)
    m.REFRESH_SEC    = 30
    m.DEX_REFRESH    = 30   ' Dexcom: fetch every 30s (readings update every 5min)
    m.dexTicks       = [0, 0, 0, 0]  ' per-account countdown; 0 = fetch now
    m.GRAPH_COUNT  = 36
    m.GRAPH_HEIGHT = 140  ' px tall for graph area
    m.GRAPH_BOTTOM = 838  ' absolute Y of graph bottom baseline
    m.GRAPH_TOP    = 680  ' absolute Y of graph top (graphBg top)
    m.GRAPH_MIN    = 40
    m.GRAPH_MAX    = 300
    m.GRAPH_LO     = 70   ' low threshold mg/dL
    m.GRAPH_HI     = 180  ' high threshold mg/dL

    m.loadingOverlay = m.top.findNode("loadingOverlay")
    m.loadingMsg     = m.top.findNode("loadingMsg")
    m.clockLabel     = m.top.findNode("clockLabel")
    m.statusLabel    = m.top.findNode("statusLabel")
    m.settingsScene  = m.top.findNode("settingsScene")

    m.cards      = [m.top.findNode("card0"),      m.top.findNode("card1"),      m.top.findNode("card2"),      m.top.findNode("card3")]
    m.cardTops   = [m.top.findNode("cardTop0"),   m.top.findNode("cardTop1"),   m.top.findNode("cardTop2"),   m.top.findNode("cardTop3")]
    m.nameLabels = [m.top.findNode("nameLabel0"), m.top.findNode("nameLabel1"), m.top.findNode("nameLabel2"), m.top.findNode("nameLabel3")]
    m.sgvLabels  = [m.top.findNode("sgvLabel0"),  m.top.findNode("sgvLabel1"),  m.top.findNode("sgvLabel2"),  m.top.findNode("sgvLabel3")]
    m.unitLabels = [m.top.findNode("unitLabel0"), m.top.findNode("unitLabel1"), m.top.findNode("unitLabel2"), m.top.findNode("unitLabel3")]
    m.rangeLabels= [m.top.findNode("rangeLabel0"),m.top.findNode("rangeLabel1"),m.top.findNode("rangeLabel2"),m.top.findNode("rangeLabel3")]
    m.deltaLabels= [m.top.findNode("deltaLabel0"),m.top.findNode("deltaLabel1"),m.top.findNode("deltaLabel2"),m.top.findNode("deltaLabel3")]
    m.ageLabels  = [m.top.findNode("ageLabel0"),  m.top.findNode("ageLabel1"),  m.top.findNode("ageLabel2"),  m.top.findNode("ageLabel3")]

    ' Arrow Poster nodes - one per card, image swapped by direction
    m.arrowImgs = [m.top.findNode("arrowImg0"), m.top.findNode("arrowImg1"), m.top.findNode("arrowImg2"), m.top.findNode("arrowImg3")]

    ' Graph node refs
    m.graphBgs     = [m.top.findNode("graphBg0"),     m.top.findNode("graphBg1"),     m.top.findNode("graphBg2"),     m.top.findNode("graphBg3")]
    m.graphHiLines = [m.top.findNode("graphHiLine0"), m.top.findNode("graphHiLine1"), m.top.findNode("graphHiLine2"), m.top.findNode("graphHiLine3")]
    m.graphLoLines = [m.top.findNode("graphLoLine0"), m.top.findNode("graphLoLine1"), m.top.findNode("graphLoLine2"), m.top.findNode("graphLoLine3")]
    m.graphLabels  = [m.top.findNode("graphLabel0"),  m.top.findNode("graphLabel1"),  m.top.findNode("graphLabel2"),  m.top.findNode("graphLabel3")]

    m.graphBars = []
    for c = 0 to 3
        bars = []
        for b = 0 to 35
            bars.push(m.top.findNode("graphBar" + Str(c).Trim() + "_" + Str(b).Trim()))
        end for
        m.graphBars.push(bars)
    end for

    m.keySeqCounter = 0
    m.accounts    = []
    m.activeCount = 0
    m.tasks       = [invalid, invalid, invalid, invalid]
    m.histTasks   = [invalid, invalid, invalid, invalid]
    m.results     = [invalid, invalid, invalid, invalid]
    m.histResults = [invalid, invalid, invalid, invalid]
    ' Track whether delta has been calculated for each card (avoid flicker)
    m.deltaReady  = [false, false, false, false]
    m.dexSessions = ["", "", "", ""]
    ' Fixed arrow origins set in layoutCards - never read back from seg nodes
    m.arrowOrigins = [[0,0],[0,0],[0,0],[0,0]]
    m.doneCount     = 0
    m.histDoneCount = 0
    m.secsLeft    = 0
    m.inSettings  = false

    ' Clock runs but we gate on m.inSettings / disclaimer
    m.inDisclaimer = true
    m.clockTimer          = CreateObject("roSGNode", "Timer")
    m.clockTimer.duration = 1
    m.clockTimer.repeat   = true
    m.clockTimer.observeField("fire", "onClockTick")
    m.clockTimer.control  = "start"

    m.screensaverTicks = 0

    ' Suppress screensaver via Task (roAppManager only works in task thread)
    m.ssTask = CreateObject("roSGNode", "ScreensaverTask")
    m.ssTask.control = "RUN"

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

function countActive(accounts as Object) as Integer
    n = 0
    for i = 0 to 3
        if isAccountActive(accounts[i]) then n = n + 1
    end for
    return n
end function

' ================================================================
' CARD LAYOUT
' ================================================================

sub layoutCards()
    n = m.activeCount
    if n = 0 then return

    if n = 1
        cardW = 1800 : gap = 60
    else if n = 2
        cardW = 880 : gap = 60
    else if n = 3
        cardW = 580 : gap = 60
    else
        cardW = 420 : gap = 60
    end if

    labelOffsetX = 40
    slot = 0
    for i = 0 to 3
        acct = m.accounts[i]
        if isAccountActive(acct)
            cardX  = gap + slot * (cardW + gap)
            labelX = cardX + labelOffsetX

            m.cards[i].translation      = [cardX, 100]
            m.cards[i].width            = cardW
            m.cardTops[i].translation   = [cardX, 100]
            m.cardTops[i].width         = cardW
            m.nameLabels[i].translation = [labelX, 130]
            m.sgvLabels[i].translation  = [labelX, 200]
            m.unitLabels[i].translation = [labelX, 390]
            m.rangeLabels[i].translation= [labelX, 550]
            m.deltaLabels[i].translation= [labelX, 590]
            m.ageLabels[i].translation  = [labelX, 630]

            ' Arrow image: positioned below unit label
            arrowOX = labelX
            arrowOY = 415
            m.arrowOrigins[i] = [arrowOX, arrowOY]
            if m.arrowImgs[i] <> invalid
                m.arrowImgs[i].translation = [arrowOX, arrowOY]
                m.arrowImgs[i].width  = 100
                m.arrowImgs[i].height = 100
            end if

            ' Graph layout
            graphMargin = 20
            graphX = cardX + graphMargin
            graphW = cardW - (graphMargin * 2)

            m.graphBgs[i].translation    = [graphX, m.GRAPH_TOP]
            m.graphBgs[i].width          = graphW
            m.graphBgs[i].height         = m.GRAPH_HEIGHT

            ' Threshold lines: map 70 and 180 mg/dL into graph pixel space
            ' Graph spans GRAPH_MIN(40) to GRAPH_MAX(300) over GRAPH_HEIGHT(140) px
            ' Y=GRAPH_TOP is the top (max), Y=GRAPH_TOP+GRAPH_HEIGHT is the bottom (min)
            graphRange = m.GRAPH_MAX - m.GRAPH_MIN
            hiRatio = (m.GRAPH_HI - m.GRAPH_MIN) / graphRange   ' 180 -> ~0.538
            loRatio = (m.GRAPH_LO - m.GRAPH_MIN) / graphRange   ' 70  -> ~0.115
            ' Y increases downward, so higher value = smaller Y offset from top
            hiY = m.GRAPH_TOP + Int((1.0 - hiRatio) * m.GRAPH_HEIGHT)
            loY = m.GRAPH_TOP + Int((1.0 - loRatio) * m.GRAPH_HEIGHT)

            m.graphHiLines[i].translation = [graphX, hiY]
            m.graphHiLines[i].width       = graphW
            m.graphHiLines[i].height      = 2
            m.graphHiLines[i].color       = "#664400"   ' amber - high threshold

            m.graphLoLines[i].translation = [graphX, loY]
            m.graphLoLines[i].width       = graphW
            m.graphLoLines[i].height      = 2
            m.graphLoLines[i].color       = "#440066"   ' purple - low threshold

            m.graphLabels[i].translation  = [graphX + 4, m.GRAPH_TOP + m.GRAPH_HEIGHT - 14]

            barW   = Int((graphW - 4) / m.GRAPH_COUNT)
            if barW < 2 then barW = 2
            barGap = barW
            for b = 0 to 35
                bar = m.graphBars[i][b]
                if bar <> invalid
                    barX = graphX + b * barGap
                    bar.translation = [barX, m.GRAPH_BOTTOM]
                    bar.width       = barW - 1
                    bar.height      = 2
                    bar.color       = "#1A1A1A"
                end if
            end for

            m.nameLabels[i].text = acct.name

            m.cards[i].visible        = true
            m.cardTops[i].visible     = true
            m.nameLabels[i].visible   = true
            m.sgvLabels[i].visible    = true
            m.unitLabels[i].visible   = true
            m.rangeLabels[i].visible  = true
            m.deltaLabels[i].visible  = true
            m.ageLabels[i].visible    = true
            m.graphBgs[i].visible     = true
            m.graphHiLines[i].visible = true
            m.graphLoLines[i].visible = true
            m.graphLabels[i].visible  = true
            if m.arrowImgs[i] <> invalid then m.arrowImgs[i].visible = true
            for b = 0 to 35
                if m.graphBars[i][b] <> invalid then m.graphBars[i][b].visible = true
            end for

            slot = slot + 1
        else
            m.cards[i].visible        = false
            m.cardTops[i].visible     = false
            m.nameLabels[i].visible   = false
            m.sgvLabels[i].visible    = false
            m.unitLabels[i].visible   = false
            m.rangeLabels[i].visible  = false
            m.deltaLabels[i].visible  = false
            m.ageLabels[i].visible    = false
            m.graphBgs[i].visible     = false
            m.graphHiLines[i].visible = false
            m.graphLoLines[i].visible = false
            m.graphLabels[i].visible  = false
            if m.arrowImgs[i] <> invalid then m.arrowImgs[i].visible = false
            for b = 0 to 35
                if m.graphBars[i][b] <> invalid then m.graphBars[i][b].visible = false
            end for
        end if
    end for
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
' FETCH
' ================================================================

sub fetchAll()
    if m.activeCount = 0 then return
    m.doneCount     = 0
    m.histDoneCount = 0
    m.statusLabel.text = "refreshing..."
    for i = 0 to 3
        m.tasks[i]     = invalid
        m.histTasks[i] = invalid
    end for
    for i = 0 to 3
        acct = m.accounts[i]
        if isAccountActive(acct)
            if acct.srcType = "dx" and m.dexTicks[i] <= 0
                ' Single combined task: one auth + one fetch gets both current and history
                baseUrl = dexBaseUrl(acct.dexRegion)
                appId   = dexAppId(acct.dexRegion)
                t = CreateObject("roSGNode", "DexcomTask")
                t.baseUrl   = baseUrl
                t.appId     = appId
                t.username  = acct.dexUser
                t.password  = acct.dexPass
                t.sessionId = m.dexSessions[i]
                t.taskIndex = i
                if i = 0
                    t.observeField("result",     "onResult0")
                    t.observeField("fetchError", "onError0")
                else if i = 1
                    t.observeField("result",     "onResult1")
                    t.observeField("fetchError", "onError1")
                else if i = 2
                    t.observeField("result",     "onResult2")
                    t.observeField("fetchError", "onError2")
                else
                    t.observeField("result",     "onResult3")
                    t.observeField("fetchError", "onError3")
                end if
                t.control = "RUN"
                m.tasks[i]     = t
                m.histTasks[i] = t   ' same task handles both
                m.dexTicks[i]  = m.DEX_REFRESH
            else if acct.srcType = "dx"
                ' Dexcom rate-limited: skip fetch this cycle, count both as done
                m.doneCount     = m.doneCount + 1
                m.histDoneCount = m.histDoneCount + 1
            else
                t = CreateObject("roSGNode", "FetchTask")
                t.url = acct.url + "/api/v1/entries/current.json"
                t.taskIndex = i
                if i = 0
                    t.observeField("result",     "onResult0")
                    t.observeField("fetchError", "onError0")
                else if i = 1
                    t.observeField("result",     "onResult1")
                    t.observeField("fetchError", "onError1")
                else if i = 2
                    t.observeField("result",     "onResult2")
                    t.observeField("fetchError", "onError2")
                else
                    t.observeField("result",     "onResult3")
                    t.observeField("fetchError", "onError3")
                end if
                t.control = "RUN"
                m.tasks[i] = t
                th = CreateObject("roSGNode", "FetchHistoryTask")
                th.url = acct.url + "/api/v1/entries.json?count=36"
                th.taskIndex = i
                if i = 0
                    th.observeField("result",     "onHistResult0")
                    th.observeField("fetchError", "onHistError0")
                else if i = 1
                    th.observeField("result",     "onHistResult1")
                    th.observeField("fetchError", "onHistError1")
                else if i = 2
                    th.observeField("result",     "onHistResult2")
                    th.observeField("fetchError", "onHistError2")
                else
                    th.observeField("result",     "onHistResult3")
                    th.observeField("fetchError", "onHistError3")
                end if
                th.control = "RUN"
                m.histTasks[i] = th
            end if
        else
            m.doneCount     = m.doneCount + 1
            m.histDoneCount = m.histDoneCount + 1
        end if
    end for
    checkDone()
end sub
' Guard against stale callbacks firing after fetchAll() has already cleared m.tasks.
' A slow/timed-out request completing in the next refresh cycle would otherwise
' crash the render thread with a null dereference, exiting the channel.
sub onResult0()
    if m.tasks[0] = invalid then return
    handleResult(0, m.tasks[0].result)
end sub
sub onResult1()
    if m.tasks[1] = invalid then return
    handleResult(1, m.tasks[1].result)
end sub
sub onResult2()
    if m.tasks[2] = invalid then return
    handleResult(2, m.tasks[2].result)
end sub
sub onResult3()
    if m.tasks[3] = invalid then return
    handleResult(3, m.tasks[3].result)
end sub
sub onError0()
    if m.tasks[0] = invalid then return
    handleError(0, m.tasks[0].fetchError)
end sub
sub onError1()
    if m.tasks[1] = invalid then return
    handleError(1, m.tasks[1].fetchError)
end sub
sub onError2()
    if m.tasks[2] = invalid then return
    handleError(2, m.tasks[2].fetchError)
end sub
sub onError3()
    if m.tasks[3] = invalid then return
    handleError(3, m.tasks[3].fetchError)
end sub

sub onHistResult0()
    if m.histTasks[0] = invalid then return
    handleHistResult(0, m.histTasks[0].result)
end sub
sub onHistResult1()
    if m.histTasks[1] = invalid then return
    handleHistResult(1, m.histTasks[1].result)
end sub
sub onHistResult2()
    if m.histTasks[2] = invalid then return
    handleHistResult(2, m.histTasks[2].result)
end sub
sub onHistResult3()
    if m.histTasks[3] = invalid then return
    handleHistResult(3, m.histTasks[3].result)
end sub
sub onHistError0() : handleHistError(0) : end sub
sub onHistError1() : handleHistError(1) : end sub
sub onHistError2() : handleHistError(2) : end sub
sub onHistError3() : handleHistError(3) : end sub

sub handleResult(idx as Integer, json as String)
    isDex = (m.accounts[idx].srcType = "dx")
    hasTask = (m.tasks[idx] <> invalid)
    if isDex and hasTask
        ns = m.tasks[idx].newSession
        if ns <> "" then m.dexSessions[idx] = ns
        entry = parseDexcomEntry(json)
        ' Combined task: also handle history from same json, increment histDoneCount
        handleHistResult(idx, json)
    else
        entry = parseEntry(json)
    end if
    m.results[idx] = entry
    m.doneCount = m.doneCount + 1
    if isAccountActive(m.accounts[idx]) then renderCard(idx, entry)
    checkDone()
end sub

sub handleError(idx as Integer, msg as String)
    m.results[idx] = {sgv: -1, direction: "Unknown", date: 0, delta: 0}
    m.doneCount = m.doneCount + 1
    ' On Dexcom error: clear session so next fetch re-auths, but keep tick at DEX_REFRESH
    ' to avoid hammering Dexcom with retries (especially on 429 rate limit)
    if m.accounts[idx].srcType = "dx"
        m.dexSessions[idx] = ""
        ' Don't reset dexTicks - let it count down normally to avoid 429 storms
        ' Dexcom uses a combined task for both current and history, so an error
        ' means history also won't arrive - count it done here to unblock checkDone()
        m.histDoneCount = m.histDoneCount + 1
    end if
    if isAccountActive(m.accounts[idx])
        m.cardTops[idx].color    = "#333333"
        m.sgvLabels[idx].text    = "---"
        m.sgvLabels[idx].color   = "#444444"
        m.rangeLabels[idx].text  = "no data"
        m.rangeLabels[idx].color = "#444444"
        m.deltaLabels[idx].text  = ""
        m.ageLabels[idx].text    = "error"
        hideArrow(idx)
    end if
    checkDone()
end sub

sub handleHistResult(idx as Integer, json as String)
    isDex = (m.accounts[idx].srcType = "dx")
    hasTask = (m.histTasks[idx] <> invalid)
    if isDex and hasTask
        ns = m.histTasks[idx].newSession
        if ns <> "" then m.dexSessions[idx] = ns
        readings = parseDexcomHistory(json)
    else
        readings = parseHistory(json)
    end if
    m.histResults[idx] = readings
    m.histDoneCount = m.histDoneCount + 1
    if isAccountActive(m.accounts[idx])
        renderGraph(idx, readings)
        count = readings.Count()
        if count >= 2
            computedDelta = readings[count - 1] - readings[count - 2]
            if m.results[idx] <> invalid
                m.results[idx].delta = computedDelta
            end if
            m.deltaReady[idx] = true
            renderDelta(idx, computedDelta)
        end if
    end if
    checkDone()
end sub

sub handleHistError(idx as Integer)
    m.histResults[idx] = []
    m.histDoneCount = m.histDoneCount + 1
    checkDone()
end sub

sub checkDone()
    if m.doneCount >= m.activeCount and m.histDoneCount >= m.activeCount
        m.secsLeft         = m.REFRESH_SEC
        m.statusLabel.text = "updated " + timeStr()
        if not m.inSettings and not m.inDisclaimer
            m.top.setFocus(true)
        end if
    end if
end sub

' ================================================================
' JSON PARSING
' ================================================================

function parseEntry(json as String) as Object
    result = {sgv: -1, direction: "Unknown", date: 0, delta: 0}
    if json = "" or json = invalid then return result
    parsed = ParseJSON(json)
    if parsed = invalid then return result
    entry = invalid
    if type(parsed) = "roArray"
        if parsed.Count() > 0 then entry = parsed[0]
    else if type(parsed) = "roAssociativeArray"
        entry = parsed
    end if
    if entry = invalid then return result
    if entry.sgv       <> invalid then result.sgv       = entry.sgv
    if entry.direction <> invalid then result.direction = entry.direction
    if entry.date      <> invalid then result.date      = entry.date
    if entry.delta     <> invalid then result.delta     = entry.delta
    return result
end function

function parseHistory(json as String) as Object
    result = []
    if json = "" or json = invalid then return result
    parsed = ParseJSON(json)
    if parsed = invalid then return result
    if type(parsed) <> "roArray" then return result
    rawCount = parsed.Count()
    for i = rawCount - 1 to 0 step -1
        entry = parsed[i]
        if entry <> invalid and entry.sgv <> invalid
            sgv = entry.sgv
            if sgv > 0 then result.push(sgv)
        end if
    end for
    return result
end function

' Parse Dexcom Share response (array of {Value, Trend, WT}) into Nightscout-style entry

function parseDexcomWt(wt as String) as Dynamic
    startPos = Instr(1, wt, "(")
    endPos   = Instr(1, wt, ")")
    if startPos > 0 and endPos > startPos
        numStr = Mid(wt, startPos + 1, endPos - startPos - 1)
        dashPos = Instr(2, numStr, "-")
        if dashPos > 1 then numStr = Mid(numStr, 1, dashPos - 1)
        plusPos = Instr(1, numStr, "+")
        if plusPos > 1 then numStr = Mid(numStr, 1, plusPos - 1)
        tsMs = Val(numStr)
        return tsMs / 1000
    end if
    return 0
end function

function parseDexcomEntry(json as String) as Object
    result = {sgv: -1, direction: "Unknown", date: 0, delta: 0}
    if json = "" or json = invalid then return result
    parsed = ParseJSON(json)
    if parsed = invalid then return result
    entry = invalid
    if type(parsed) = "roArray"
        if parsed.Count() > 0 then entry = parsed[0]
    else if type(parsed) = "roAssociativeArray"
        entry = parsed
    end if
    if entry = invalid then return result
    if entry.Value <> invalid then result.sgv       = entry.Value
    if entry.Trend <> invalid then result.direction = entry.Trend
    if entry.WT <> invalid then result.date = parseDexcomWt(entry.WT) * 1000
    return result
end function

function parseDexcomHistory(json as String) as Object
    result = []
    if json = "" or json = invalid then return result
    parsed = ParseJSON(json)
    if parsed = invalid or type(parsed) <> "roArray" then return result
    rawCount = parsed.Count()
    for i = rawCount - 1 to 0 step -1
        entry = parsed[i]
        if entry <> invalid and entry.Value <> invalid
            sgv = entry.Value
            if sgv > 0 then result.push(sgv)
        end if
    end for
    return result
end function

function dexBaseUrl(region as String) as String
    if region = "ous" then return "https://shareous1.dexcom.com/ShareWebServices/Services"
    if region = "jp"  then return "https://share.dexcom.jp/ShareWebServices/Services"
    return "https://share2.dexcom.com/ShareWebServices/Services"
end function

function dexAppId(region as String) as String
    if region = "jp" then return "d8665ade-9673-4e27-9ff6-92db4ce13d13"
    return "d89443d2-327c-4a6f-89e5-496bbb0317db"
end function

sub renderCard(idx as Integer, e as Object)
    sgv = e.sgv
    ts  = e.date

    stale = false
    if ts > 0
        dt      = CreateObject("roDateTime")
        ageMins = Int((dt.AsSeconds() - Int(ts / 1000)) / 60)
        if ageMins > 10 then stale = true
    end if

    col = sgvColor(sgv)
    if stale then col = "#555555"

    m.cardTops[idx].color    = col
    m.sgvLabels[idx].color   = col
    m.rangeLabels[idx].color = col

    if sgv > 0
        m.sgvLabels[idx].text = stri(sgv)
    else
        m.sgvLabels[idx].text = "---"
    end if

    renderArrow(idx, e.direction, col)

    if stale
        m.rangeLabels[idx].text = "STALE"
    else
        m.rangeLabels[idx].text = rangeStr(sgv)
    end if

    if ts > 0
        dt      = CreateObject("roDateTime")
        ageMins = Int((dt.AsSeconds() - Int(ts / 1000)) / 60)
        if ageMins < 1
            m.ageLabels[idx].text = "just now"
        else if ageMins = 1
            m.ageLabels[idx].text = "1 min ago"
        else if ageMins < 60
            m.ageLabels[idx].text = stri(ageMins) + " mins ago"
        else
            m.ageLabels[idx].text = "over 1 hr ago"
        end if
        if stale
            m.ageLabels[idx].color = "#FF6B00"
        else
            m.ageLabels[idx].color = "#333333"
        end if
    else
        m.ageLabels[idx].text = ""
    end if
end sub

' Render just the delta label - called only from handleHistResult
sub renderDelta(idx as Integer, delt as Integer)
    if delt > 0
        m.deltaLabels[idx].text = "+" + stri(delt) + " mg/dL"
    else if delt < 0
        m.deltaLabels[idx].text = stri(delt) + " mg/dL"
    else
        m.deltaLabels[idx].text = "+/-0 mg/dL"
    end if
end sub

' ================================================================
' RENDER ARROW - draws a directional arrow from Rectangle segments
'
' Arrow canvas: 120px wide x 90px tall, origin = arrowSegs[idx][0].translation
' Segments: [0]=shaft, [1]=leftWing, [2]=rightWing, [3]=extra shaft (DoubleUp/Down), [4]=unused(hidden)
'
' Each direction is built from positioned Rectangles.
' Diagonals are approximated with square blocks - looks clean at TV resolution.
'
' Layout uses these constants relative to the arrow origin point (ox, oy):
'   Arrow box: 120 wide, 90 tall
'   Shaft thickness: 10px
'   Wing arm: ~36px long, 10px thick, shifted to suggest 45 degrees
' ================================================================

sub renderArrow(idx as Integer, direction as String, col as String)
    img = m.arrowImgs[idx]
    if img = invalid then return

    if direction = "DoubleUp"
        img.uri = "pkg:/images/arrow_double_up.png"
    else if direction = "SingleUp"
        img.uri = "pkg:/images/arrow_up.png"
    else if direction = "FortyFiveUp"
        img.uri = "pkg:/images/arrow_up_right.png"
    else if direction = "Flat"
        img.uri = "pkg:/images/arrow_right.png"
    else if direction = "FortyFiveDown"
        img.uri = "pkg:/images/arrow_down_right.png"
    else if direction = "SingleDown"
        img.uri = "pkg:/images/arrow_down.png"
    else if direction = "DoubleDown"
        img.uri = "pkg:/images/arrow_double_down.png"
    else
        img.uri = "pkg:/images/arrow_right.png"
    end if

    img.blendColor = col
end sub

sub hideArrow(idx as Integer)
    if m.arrowImgs[idx] <> invalid then m.arrowImgs[idx].uri = ""
end sub

' ================================================================
' RENDER GRAPH
' ================================================================

sub renderGraph(idx as Integer, readings as Object)
    count  = readings.Count()
    graphH = m.GRAPH_HEIGHT
    minVal = m.GRAPH_MIN
    maxVal = m.GRAPH_MAX
    range  = maxVal - minVal

    n = m.activeCount
    if n = 1
        cardW = 1800 : gap = 60
    else if n = 2
        cardW = 880 : gap = 60
    else if n = 3
        cardW = 580 : gap = 60
    else
        cardW = 420 : gap = 60
    end if

    slot = 0
    for s = 0 to idx - 1
        if isAccountActive(m.accounts[s]) then slot = slot + 1
    end for

    graphMargin = 20
    graphX = gap + slot * (cardW + gap) + graphMargin
    graphW = cardW - (graphMargin * 2)
    barW   = Int((graphW - 4) / m.GRAPH_COUNT)
    if barW < 2 then barW = 2
    barGap = barW
    dotSize = 5

    for b = 0 to 35
        bar = m.graphBars[idx][b]
        if bar <> invalid
            barX = graphX + b * barGap
            readingIdx = count - (35 - b) - 1

            if readingIdx >= 0 and readingIdx < count
                sgv = readings[readingIdx]
                if sgv < minVal then sgv = minVal
                if sgv > maxVal then sgv = maxVal

                ratio = (sgv - minVal) / range
                ' Y increases downward; high SGV = near top of graph
                dotY  = m.GRAPH_TOP + Int((1.0 - ratio) * m.GRAPH_HEIGHT)

                bar.width       = dotSize
                bar.height      = dotSize
                bar.translation = [barX, dotY]
                bar.color       = sgvColor(sgv)
            else
                bar.width       = dotSize
                bar.height      = dotSize
                bar.translation = [barX, m.GRAPH_TOP + m.GRAPH_HEIGHT - dotSize]
                bar.color       = "#1A1A1A"
            end if
        end if
    end for
end sub

' ================================================================
' HELPERS
' ================================================================

function sgvColor(sgv as Integer) as String
    if sgv <= 0   then return "#444444"
    if sgv < 55   then return "#FF2D2D"
    if sgv < 70   then return "#FF6B00"
    if sgv <= 180 then return "#00C853"
    if sgv <= 250 then return "#FFD600"
    return "#FF2D2D"
end function

function rangeStr(sgv as Integer) as String
    if sgv <= 0   then return ""
    if sgv < 55   then return "URGENT LOW"
    if sgv < 70   then return "LOW"
    if sgv <= 180 then return "IN RANGE"
    if sgv <= 250 then return "HIGH"
    return "URGENT HIGH"
end function

sub onClockTick()
    m.clockLabel.text = timeStr()


    if m.inDisclaimer then return
    if m.inSettings then return
    if m.accounts.Count() = 0 then return

    if m.secsLeft > 0
        m.secsLeft = m.secsLeft - 1
        for di = 0 to 3
            if m.dexTicks[di] > 0 then m.dexTicks[di] = m.dexTicks[di] - 1
        end for
        if m.secsLeft = 0 then fetchAll()
    end if

    ' Only re-render cards from clock tick (age label updates etc).
    ' Delta is NOT touched here - it only updates via handleHistResult.
    for i = 0 to 3
        e = m.results[i]
        if e <> invalid and e.sgv > 0 and isAccountActive(m.accounts[i])
            renderCard(i, e)
        end if
    end for
end sub

function timeStr() as String
    dt   = CreateObject("roDateTime")
    dt.ToLocalTime()
    h    = dt.GetHours()
    mins = dt.GetMinutes()
    ampm = "AM"
    if h >= 12 then ampm = "PM"
    if h > 12  then h = h - 12
    if h = 0   then h = 12
    mp = stri(mins)
    if mins < 10 then mp = "0" + mp
    return stri(h) + ":" + mp + " " + ampm
end function

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
