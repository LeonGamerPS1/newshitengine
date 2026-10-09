import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.gameplay.Character;

function hitNote(note, isOpponent)
{
	var strum = note.actorline.actors.members[note.lane];
	strum.scale.set(note.scale.x * 1.25, .7 * .75);

	FlxTween.cancelTweensOf(strum);
	FlxTween.tween(strum, {"scale.x": .7, "scale.y": .7}, 0.15 * 2,{ease:FlxEase.expoInOut});
}

