local cardName = "KnightsEdgyRedSlashDeltaruneChapter2PredictionMechanicCard"
local allowCountdown = true
local mayPause = true

function onCreate()
	if isStoryMode and not getProperty('seenCutscene') then
		makeLuaSprite(cardName, "KNIGHT_INSTRUCTIONS", 0, 0)
		addLuaSprite(cardName, false)
		setObjectCamera(cardName, 'other')
		allowCountdown = false
	end
end

function onPause()
	if not allowCountdown or not mayPause then
		return Function_Stop
	end

	return Function_Continue
end

function onUpdate()
	if mayPause == false then
		mayPause = true
	end

	if keyJustPressed("pause") then
		if not allowCountdown then
			if keyboardJustPressed("ESCAPE") then
				endSong()
			else
				allowCountdown = true
				mayPause = false
				removeLuaSprite(cardName, true)
				startCountdown()
			end
		end
	end
end

function onStartCountdown()
	if not allowCountdown then
		return Function_Stop
	end

	return Function_Continue
end