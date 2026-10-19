local roaring = false;

function onUpdate(elapsed)
	if dadName == 'knight' then --replace the name for your character name
	  if curStep >= 0 then
  
		songPos = getSongPosition()
  
		local currentBeat = (songPos/1000)*(bpm/200)
  
		doTweenY(dadTweenY, 'dad', 480+20*math.sin((currentBeat*1.7)*math.pi),0.0005);

	  end
	end
end