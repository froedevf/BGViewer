' ScreensaverTask.brs
' Plays a silent audio clip on loop to keep the channel active and prevent
' Roku's OS-level inactivity timeout from exiting the app.

sub init()
    m.top.functionName = "run"
end sub

sub run()
    print "[ScreensaverTask] starting audio keep-alive"
    audioPlayer = CreateObject("roAudioPlayer")
    if audioPlayer = invalid
        print "[ScreensaverTask] ERROR: roAudioPlayer is invalid"
        return
    end if

    msgPort = CreateObject("roMessagePort")
    audioPlayer.SetMessagePort(msgPort)

    content = CreateObject("roAssociativeArray")
    content.url = "pkg:/audio/silence.wav"
    content.StreamFormat = "wav"

    audioPlayer.AddContent(content)
    audioPlayer.SetLoop(true)
    ok = audioPlayer.Play()
    print "[ScreensaverTask] Play() returned: " + ok.toStr()

    while true
        msg = wait(0, msgPort)
        if type(msg) = "roAudioPlayerEvent"
            print "[ScreensaverTask] audio event: " + msg.getMessage() + " index=" + msg.getIndex().toStr()
            if msg.isRequestFailed()
                print "[ScreensaverTask] ERROR: audio failed, retrying..."
                audioPlayer.Stop()
                audioPlayer.Play()
            end if
        end if
    end while
end sub
