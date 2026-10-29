package objects;

import shaders.ColorSwap;

class Actor extends FlxOffsetSprite
{
	public var lane:Int = 0;
	public var lastTexture:String = '';
	public var resetAnim:Float = 0;

	static public var dirs = ['left', 'down', 'up', 'right'];

	public static var Width:Float = 160 * 0.7;

	public var holding:Bool = false;

	public var flipScroll:Bool = false;

	public var actorline:ActorLine;
	public var colorSwap:ColorSwap;

	public function new(lane:Int = 0, texture:String = 'NOTE_assets')
	{
		super();

		this.lane = lane;
		loadTexture(texture);
	}

	public function loadTexture(texture:String = 'NOTE_assets')
	{
		if (texture == lastTexture)
			return;
		lastTexture = Note.currentSkin ?? texture;
		final n = dirs[lane];
		frames = Paths.getSparrowAtlas(lastTexture);
		animation.addByPrefix('grey', 'arrow' + n.toUpperCase(), 24, true);
		animation.addByPrefix('press', n + ' press', 24, false);
		animation.addByPrefix('confirm', n + ' confirm', 24, false);
		playAnim('grey');
		scale.set(Note.currentNoteScale, Note.currentNoteScale);
		updateHitbox();
		antialiasing = Note.currentBlurring;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('grey');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, force = true)
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
	}
}
