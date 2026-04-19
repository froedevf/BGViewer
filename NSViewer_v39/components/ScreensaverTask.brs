' ScreensaverTask.brs
' Plays a silent audio clip on loop to keep the channel active and prevent
' Roku's OS-level inactivity timeout from exiting the app.

sub init()
    m.top.functionName = "run"
end sub

sub run()
    audioPlayer = CreateObject("roAudioPlayer")
    if audioPlayer = invalid then return

    msgPort = CreateObject("roMessagePort")
    audioPlayer.SetMessagePort(msgPort)

    content = CreateObject("roAssociativeArray")
    content.url = "pkg:/audio/silence.wav"
    content.StreamFormat = "wav"

    audioPlayer.AddContent(content)
    audioPlayer.SetLoop(true)
    audioPlayer.Play()

    while true
        wait(0, msgPort)
    end while
end sub
