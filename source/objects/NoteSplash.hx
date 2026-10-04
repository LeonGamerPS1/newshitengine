package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import haxe.io.Path;

class NoteSplash extends FlxSprite
{
	public function new(x:Float, y:Float, noteData:Int = 0):Void
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('splashes');

		animation.addByPrefix('note1-0', 'note splash blue 1', 24, false);
		animation.addByPrefix('note2-0', 'note splash green 1', 24, false);
		animation.addByPrefix('note0-0', 'note splash purple 1', 24, false);
		animation.addByPrefix('note3-0', 'note splash red 1', 24, false);
		animation.addByPrefix('note1-1', 'note splash blue 2', 24, false);
		animation.addByPrefix('note2-1', 'note splash green 2', 24, false);
		animation.addByPrefix('note0-1', 'note splash purple 2', 24, false);
		animation.addByPrefix('note3-1', 'note splash red 2', 24, false);

		alpha = 0.75;
	}

	public var strum:Actor = null;

	public function setupNoteSplash(strumNote:Actor)
	{
		strum = strumNote;
		shader = strumNote.shader;
		setPosition(strumNote.x, strumNote.y);

		if (frames == null)
			frames = Paths.getSparrowAtlas('noteskins/funkin/noteSplashes');

		animation.play('note' + (strumNote.lane) % 4 + '-' + FlxG.random.int(0, 1), true);
		animation.curAnim.frameRate = 24 + FlxG.random.int(-5, 5);
		scale.setXY(.7);
		antialiasing = true;
		updateHitbox();
		centerOffsets();
		centerOrigin();
		setPosition(strumNote.x + (strumNote.width * 0.5 - width * 0.5), strumNote.y + (strumNote.height * 0.5 - height * 0.5));
		alpha = 1;
	}

	override function kill()
	{
		alpha = 0;
		super.kill();
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim.finished)
		{
			kill();
		}

		super.update(elapsed);
	}
}
