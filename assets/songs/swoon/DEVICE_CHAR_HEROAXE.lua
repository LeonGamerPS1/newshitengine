local targetCharacter = 'susie' -- The character they're supposed to be
local playable = true -- Makes it so the player can control them
local flipped = false -- Flips them as if they were on the player side
local instanceName = 'susie' -- The instance name
local noteTypes = {'Susie Sing'} -- This is a table so you can add as many as you want

function onCreate()
	createInstance(instanceName, "objects.Character", {290, 620, targetCharacter, flipped})
	addInstance(instanceName, true)
end

function onCreatePost()
	setObjectOrder('susie', getObjectOrder('boyfriendGroup')-1);
end

local singAnims = {'LEFT','DOWN', 'UP','RIGHT'}

function isValidNoteType(targetType)
	for index, noteType in pairs(noteTypes) do
		if noteType == targetType then
			return true
		end
	end
	return false
end

function handleNote(id, dir, noteType, isSustain)
	if isValidNoteType(noteType) == true then
		local animToPlay = 'sing' .. singAnims[dir+1] .. getPropertyFromGroup('notes', id, 'animSuffix')
		local canPlay = true
		if isSustain == true then
			local holdAnim = animToPlay .. '-hold'
			if callMethod(instanceName..".animation.exists", {holdAnim}) then
				animToPlay = holdAnim
			end
			local current = callMethod(instanceName..".getAnimationName", {})
			if current == holdAnim or current == holdAnim .. '-loop' then
				canPlay = false
			end
		end

		if canPlay == true then
			callMethod(instanceName..".playAnim", {animToPlay, true})
		end
		setProperty(instanceName..".holdTimer", 0)
	end
end

function opponentNoteHit(id, dir, noteType, isSustain)
	if playable == false then
		handleNote(id, dir, noteType, isSustain)
	end
end

function goodNoteHit(id, dir, noteType, isSustain)
	if playable == true then
		handleNote(id, dir, noteType, isSustain)
	end
end