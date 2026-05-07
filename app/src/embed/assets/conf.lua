function love.conf(t)
    t.console = true
    t.window.title = "Purge"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.fullscreentype = "desktop"
    -- 强制焦点相关设置
    t.window.usedpiscale = false
    t.window.highdpi = false
end