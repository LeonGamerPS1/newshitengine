package objects;

class Actor extends FlxSprite
{
	public var lane:Int = 0;
	public var lastTexture:String = '';
	public var resetAnim:Float = 0;

	static public var dirs = ['left', 'down', 'up', 'right'];

    public static var Width:Float = 160 * 0.7;

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
		final n = dirs[lane];
		frames = Paths.getSparrowAtlas(texture);
		animation.addByPrefix('grey', 'arrow' + n.toUpperCase(), 24, false);
		animation.addByPrefix('press', n + ' press', 24, false);
		animation.addByPrefix('confirm', n + ' confirm', 24, false);
		playAnim('grey');
		scale.setXY(.7);
		updateHitbox();
        antialiasing = true;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String)
	{
		animation.play(anim, true);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
	}
}
