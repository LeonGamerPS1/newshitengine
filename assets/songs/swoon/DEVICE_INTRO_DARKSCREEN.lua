function onCreate()
    makeLuaSprite('escuro', '', -1000, -200)
    makeGraphic('escuro', 4000, 2000, '000000')
    addLuaSprite('escuro', true);
	setProperty('escuro.alpha', 1);
end

function onCountdownTick()
    doTweenAlpha('escuro', 'escuro', 0, 0.5);
end

function onUpdate()
    if curStep > 0 then
        removeLuaSprite('escuro');
    end
end