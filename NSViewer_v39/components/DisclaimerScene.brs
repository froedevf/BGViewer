' ============================================================
' DisclaimerScene.brs
' Shows a one-time disclaimer on first launch.
' Sets accepted=true when user presses OK/Play.
' ============================================================

sub init()
    m.top.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "OK" or key = "play" or key = "select"
        m.top.accepted = true
        return true
    end if
    return false
end function
