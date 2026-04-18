' DexcomHistoryTask.brs
' Fetches 36 readings (3h) from Dexcom Share. Reuses cached sessionId.

sub init()
    m.top.functionName = "doFetch"
end sub

sub doFetch()
    sessionId = m.top.sessionId

    if sessionId = ""
        sessionId = authenticate()
        if sessionId = ""
            if m.top.fetchError = "" then m.top.fetchError = "Auth failed"
            return
        end if
    end if

    json = fetchReadings(sessionId, 180, 36)

    if json = "REAUTH"
        sessionId = authenticate()
        if sessionId = ""
            if m.top.fetchError = "" then m.top.fetchError = "Re-auth failed"
            return
        end if
        json = fetchReadings(sessionId, 180, 36)
    end if

    if json <> "" and json <> "REAUTH"
        m.top.newSession = sessionId
        m.top.result     = json
    else
        if m.top.fetchError = "" then m.top.fetchError = "No data"
    end if
end sub

function authenticate() as String
    q    = Chr(34)
    url  = m.top.baseUrl + "/General/AuthenticatePublisherAccount"
    body = "{" + q + "accountName" + q + ":" + q + m.top.username + q
    body = body + "," + q + "password" + q + ":" + q + m.top.password + q
    body = body + "," + q + "applicationId" + q + ":" + q + m.top.appId + q + "}"
    resp = postJson(url, body)
    if resp = "" then return ""
    accountId = stripQuotes(resp)

    url  = m.top.baseUrl + "/General/LoginPublisherAccountById"
    body = "{" + q + "accountId" + q + ":" + q + accountId + q
    body = body + "," + q + "password" + q + ":" + q + m.top.password + q
    body = body + "," + q + "applicationId" + q + ":" + q + m.top.appId + q + "}"
    resp = postJson(url, body)
    if resp = "" then return ""
    return stripQuotes(resp)
end function

function fetchReadings(sessionId as String, minutes as Integer, maxCount as Integer) as String
    q    = Chr(34)
    url  = m.top.baseUrl + "/Publisher/ReadPublisherLatestGlucoseValues"
    body = "{" + q + "sessionId" + q + ":" + q + sessionId + q
    body = body + "," + q + "minutes" + q + ":" + Str(minutes).Trim()
    body = body + "," + q + "maxCount" + q + ":" + Str(maxCount).Trim() + "}"
    resp = postJson(url, body)
    if resp = "" then return ""
    if resp = "[]" or resp = "null" then return "REAUTH"
    return resp
end function

function postJson(url as String, body as String) as String
    xfer = CreateObject("roUrlTransfer")
    xfer.SetUrl(url)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.AddHeader("Content-Type", "application/json")
    xfer.AddHeader("Accept", "application/json")
    msgPort = CreateObject("roMessagePort")
    xfer.SetMessagePort(msgPort)
    xfer.AsyncPostFromString(body)
    msg = wait(12000, msgPort)
    if msg = invalid then return ""
    code = msg.GetResponseCode()
    resp = msg.GetString()
    print "DexcomHistoryTask[" + stri(m.top.taskIndex) + "] -> HTTP " + stri(code)
    if code = 200 then return resp
    if m.top.fetchError = ""
        m.top.fetchError = "HTTP " + stri(code)
    end if
    return ""
end function

function stripQuotes(s as String) as String
    s = s.Trim()
    if Len(s) >= 2 and Mid(s, 1, 1) = Chr(34) and Mid(s, Len(s), 1) = Chr(34)
        return Mid(s, 2, Len(s) - 2)
    end if
    return s
end function
