' ScreensaverTask.brs
' Keep-alive is handled by a Video node on the render thread in MainScene.
' This task is retained as a no-op so MainScene wiring does not need to change.

sub init()
    m.top.functionName = "run"
end sub

sub run()
end sub
