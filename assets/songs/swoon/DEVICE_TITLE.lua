function onCreate()
    setPropertyFromClass("openfl.Lib", "application.window.title","SEEK'S ULTIMATE DELTARUNE MOD: SWOON by Seeks_stuff")
end

function onUpdate()
    if getProperty("health") < 0 then
        setPropertyFromClass("openfl.Lib", "application.window.title","SEEK'S ULTIMATE DELTARUNE MOD")
    end
end
