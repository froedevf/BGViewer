' ScreensaverTask.brs
' Plays a silent looping video to satisfy Roku's OS-level video watchdog
' and prevent the channel from being exited after ~130 minutes of non-video activity.

sub init()
    m.top.functionName = "run"
end sub

sub run()
    print "[ScreensaverTask] starting video keep-alive"
    videoPlayer = CreateObject("roVideoPlayer")
    if videoPlayer = invalid
        print "[ScreensaverTask] ERROR: roVideoPlayer is invalid"
        return
    end if

    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetMessagePort(msgPort)

    content = CreateObject("roAssociativeArray")
    content.url = "pkg:/video/keepalive.mp4"
    content.StreamFormat = "mp4"
    content.Loop = true

    videoPlayer.SetContent(content)
    videoPlayer.SetLoop(true)
    ok = videoPlayer.Play()
    print "[ScreensaverTask] Play() returned: " + ok.toStr()

    while true
        msg = wait(0, msgPort)
        if type(msg) = "roVideoPlayerEvent"
            print "[ScreensaverTask] video event: " + msg.getMessage()
            if msg.isRequestFailed() or msg.isError()
                print "[ScreensaverTask] ERROR: " + msg.getMessage() + " - retrying..."
                videoPlayer.Stop()
                videoPlayer.Play()
            end if
            if msg.isPlaybackPosition()
                ' Looping - do nothing
            end if
        end if
    end while
end sub
