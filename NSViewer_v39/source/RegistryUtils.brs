' RegistryUtils.brs

function loadAccounts() as Object
    reg = CreateObject("roRegistrySection", "nightscout")
    accounts = []
    idxs = ["0", "1", "2", "3"]
    for i = 0 to 3
        idx = idxs[i]
        name      = regRead(reg, "acct_" + idx + "_name")
        url       = regRead(reg, "acct_" + idx + "_url")
        srcType   = regRead(reg, "acct_" + idx + "_type")
        dexUser   = regRead(reg, "acct_" + idx + "_dexuser")
        dexPass   = regRead(reg, "acct_" + idx + "_dexpass")
        dexRegion = regRead(reg, "acct_" + idx + "_dexregion")
        if srcType = "" then srcType = "ns"
        if dexRegion = "" then dexRegion = "us"
        accounts.Push({
            name:      name,
            url:       url,
            srcType:   srcType,
            dexUser:   dexUser,
            dexPass:   dexPass,
            dexRegion: dexRegion
        })
    end for
    return accounts
end function

sub saveAccounts(accounts as Object)
    reg = CreateObject("roRegistrySection", "nightscout")
    idxs = ["0", "1", "2", "3"]
    for i = 0 to 3
        idx  = idxs[i]
        acct = accounts[i]
        reg.Write("acct_" + idx + "_name",      acct.name)
        reg.Write("acct_" + idx + "_url",       acct.url)
        reg.Write("acct_" + idx + "_type",      acct.srcType)
        reg.Write("acct_" + idx + "_dexuser",   acct.dexUser)
        reg.Write("acct_" + idx + "_dexpass",   acct.dexPass)
        reg.Write("acct_" + idx + "_dexregion", acct.dexRegion)
    end for
    reg.Flush()
end sub

function regRead(reg as Object, key as String) as String
    if reg.Exists(key) then return reg.Read(key)
    return ""
end function

function isAccountActive(acct as Object) as Boolean
    if acct.srcType = "dx"
        active = (acct.dexUser <> "" and acct.dexPass <> "")
        return active
    end if
    active = (acct.url <> "")
    return active
end function
