' DexcomCurrentTask.brs

sub init()
    m.top.functionName = "doFetch"
end sub

sub doFetch()
    idx = m.top.taskIndex
    sessionId = m.top.sessionId
    print "[DexCur" + stri(idx) + "] start. cached session=" + sessionId

    if sessionId = ""
        print "[DexCur" + stri(idx) + "] no session, authenticating..."
        sessionId = authenticate()
        print "[DexCur" + stri(idx) + "] auth result=" + sessionId
        if sessionId = ""
            if m.top.fetchError = "" then m.top.fetchError = "Auth failed"
            return
        end if
    end if

    print "[DexCur" + stri(idx) + "] fetching readings with session=" + sessionId
    json = fetchReadings(sessionId, 10, 1)
    print "[DexCur" + stri(idx) + "] fetchReadings result=" + json

    if json = "REAUTH"
        print "[DexCur" + stri(idx) + "] session expired, re-authing..."
        sessionId = authenticate()
        print "[DexCur" + stri(idx) + "] re-auth result=" + sessionId
        if sessionId = ""
            if m.top.fetchError = "" then m.top.fetchError = "Re-auth failed"
            return
        end if
        json = fetchReadings(sessionId, 10, 1)
        print "[DexCur" + stri(idx) + "] retry result=" + json
    end if

    if json <> "" and json <> "REAUTH"
        print "[DexCur" + stri(idx) + "] SUCCESS, setting result"
        m.top.newSession = sessionId
        m.top.result     = json
    else
        print "[DexCur" + stri(idx) + "] FAIL, json=" + json + " err=" + m.top.fetchError
        if m.top.fetchError = "" then m.top.fetchError = "No data"
    end if
end sub

function authenticate() as String
    q = Chr(34)
    url  = m.top.baseUrl + "/General/AuthenticatePublisherAccount"
    body = "{" + q + "accountName" + q + ":" + q + m.top.username + q
    body = body + "," + q + "password" + q + ":" + q + m.top.password + q
    body = body + "," + q + "applicationId" + q + ":" + q + m.top.appId + q + "}"
    print "[DexCur auth] POST AuthenticatePublisherAccount"
    resp = postJson(url, body)
    print "[DexCur auth] step1 resp=" + resp
    if resp = "" then return ""
    accountId = stripQuotes(resp)
    print "[DexCur auth] accountId=" + accountId

    url  = m.top.baseUrl + "/General/LoginPublisherAccountById"
    body = "{" + q + "accountId" + q + ":" + q + accountId + q
    body = body + "," + q + "password" + q + ":" + q + m.top.password + q
    body = body + "," + q + "applicationId" + q + ":" + q + m.top.appId + q + "}"
    print "[DexCur auth] POST LoginPublisherAccountById"
    resp = postJson(url, body)
    print "[DexCur auth] step2 resp=" + resp
    if resp = "" then return ""
    return stripQuotes(resp)
end function

function fetchReadings(sessionId as String, minutes as Integer, maxCount as Integer) as String
    q    = Chr(34)
    url  = m.top.baseUrl + "/Publisher/ReadPublisherLatestGlucoseValues"
    body = "{" + q + "sessionId" + q + ":" + q + sessionId + q
    body = body + "," + q + "minutes" + q + ":" + Str(minutes).Trim()
    body = body + "," + q + "maxCount" + q + ":" + Str(maxCount).Trim() + "}"
    print "[DexCur fetch] body=" + body
    resp = postJson(url, body)
    print "[DexCur fetch] resp=" + resp
    if resp = "" then return ""
    if resp.Trim() = "[]" or resp.Trim() = "null" then return "REAUTH"
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
    msg = wait(15000, msgPort)
    if msg = invalid
        print "[DexCur] TIMEOUT on " + url
        return ""
    end if
    code = msg.GetResponseCode()
    resp = msg.GetString()
    print "[DexCur] HTTP " + stri(code) + " url=" + url
    print "[DexCur] response=" + resp
    if code = 200 then return resp
    if m.top.fetchError = "" then m.top.fetchError = "HTTP " + stri(code)
    return ""
end function

function stripQuotes(s as String) as String
    s = s.Trim()
    if Len(s) >= 2 and Mid(s, 1, 1) = Chr(34) and Mid(s, Len(s), 1) = Chr(34)
        return Mid(s, 2, Len(s) - 2)
    end if
    return s
end function
