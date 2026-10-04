package objects;

import objects.gameplay.Character;
import shaders.RGB;

class Note extends FlxSprite
{
	public var actorline:ActorLine;

	public var time:Float = 0;
	public var lane:Int = 0;
	public var hit:Bool = false;
	public var type:String = '';

	public var mA:Float = 1;
	public var isTrail:Bool = false;
	public var isTail:Bool = false;

	public var lastTexture:String = '';
	public var seglength:Float = 0;

	static public var dirs = ['purple', 'blue', 'green', 'red'];

	public var canBeHit(get, null):Bool;
	public var character:Character;

	public static var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];

	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;

	public var parentNote:Note;
	public var prevNote:Note;

	public var hitByenemy = false;

	public function new(time:Float = 0, data:Int = 0, isT:Bool = false, isEn:Bool = false, t:String = 'NOTE_assets')
	{
		super();
		parentNote = this;
		this.time = time;
		lane = data;
		isTrail = isT;
		isTail = isEn;

		loadTexture(t);
	}

	public function loadTexture(texture:String = 'NOTE_assets')
	{
		if (texture == lastTexture)
			return;
		lastTexture = texture;
		final n = dirs[lane];
		frames = Paths.getSparrowAtlas(texture);
		animation.addByPrefix('colored', n + '0', 24);
		animation.addByPrefix('segment', n + ' hold piece0', 24);
		animation.addByPrefix('tail', n + ' hold end0', 24);
		playAnim('colored');

		scale.setXY(.7);

		if (isTrail)
		{
			mA = .7;
			earlyHitMult = 0;
			alpha = mA;
			playAnim(!isTail ? 'segment' : 'tail');
		}
		updateHitbox();
		antialiasing = true;
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

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (actorline != null && actorline.autoPlay)
		{
			if (!hit && time <= Conductor.time)
				hit = true;
		}
	}

	public function getDistance(actor:Actor, speed:Float = 1):Float
	{
		return (time - Conductor.time) * (0.45 * speed) * (actor?.flipScroll ? -1 : 1);
	}

	public var lastSpeedSus:Float = -1;

	public function updateSusLength(speed:Float = 1)
	{
		if (speed != lastSpeedSus && !isTail)
		{
			lastSpeedSus = speed;
			scale.y = (seglength * 0.45 * speed) / frameHeight;

			updateHitbox();
		}
	}

	function get_canBeHit():Bool
	{
		return ((time > Conductor.time - Conductor.offset - (Conductor.sfz * lateHitMult)
			&& time < Conductor.time - Conductor.offset + (Conductor.sfz * earlyHitMult)))
			&& !actorline.autoPlay;
	}

	public var ignoreNote = false;

	public function clipToStrumNote(myStrum:Actor)
	{
		var center:Float = myStrum.y + Actor.Width * .5;
		final mustPress = !actorline.autoPlay;
		if (isTrail && (mustPress || !ignoreNote) && (!mustPress || (hit || (prevNote.hit && !canBeHit))))
		{
			var swagRect:FlxRect = clipRect;
			if (swagRect == null)
				swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.flipScroll)
			{
				if (y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}
}
