' ============================================================
' FetchTask.brs
' Fetches a Nightscout /api/v1/entries/current.json endpoint
' on a background Task thread.
' ============================================================

sub init()
    m.top.functionName = "doFetch"
end sub

sub doFetch()
    url = m.top.url
    if url = "" or url = invalid
        m.top.fetchError = "No URL"
        return
    end if

    print "FetchTask[" + stri(m.top.taskIndex) + "]: " + url

    xfer = CreateObject("roUrlTransfer")
    xfer.SetUrl(url)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.EnableFreshConnection(true)
    xfer.AddHeader("User-Agent", "RokuCGM/1.0 BrightScript")
    xfer.AddHeader("Accept",     "application/json")

    tmpFile = "tmp:/ns_entry_" + stri(m.top.taskIndex) + ".json"
    code    = xfer.GetToFile(tmpFile)

    print "FetchTask[" + stri(m.top.taskIndex) + "]: HTTP " + stri(code)

    if code = 200
        content = ReadAsciiFile(tmpFile)
        CreateObject("roFileSystem").Delete(tmpFile)
        if content = "" or content = invalid
            m.top.fetchError = "Empty response"
        else
            m.top.result = content
        end if
    else if code <= 0
        m.top.fetchError = "Network error (" + stri(code) + ")"
    else
        m.top.fetchError = "HTTP " + stri(code)
    end if
end sub
