package objects;

import objects.gameplay.Character;
import shaders.ColorSwap;

class Note extends FlxOffsetSprite
{
	public static var swagWidth:Float = Actor.Width;

	public var actorline:ActorLine;

	public var time:Float = 0;
	public var lane:Int = 0;
	public var hit:Bool = false;
	public var type:String = '';

	public var mA:Float = 1;
	public var isTrail:Bool = false;
	public var isTail:Bool = false;
	public var rating = "none";

	public var lastTexture:String = '';
	public var seglength:Float = 0;

	static public var dirs = ['purple', 'blue', 'green', 'red'];

	public var canBeHit(get, null):Bool;
	public var character:Character;

	/** If set, will load the texture instead of default on load**/
	public static var currentSkin:String;

	/**Useful for pixel notes and other note skins are smaller or bigger than usual**/
	public static var currentNoteScale:Float = .7;

	/**
	 * Disable this if your noteskin is too blurry, enable this if it looks too pixelated
	 */
	public static var currentBlurring:Bool = true;

	public var earlyHitMult:Float = 0;
	public var lateHitMult:Float = 1;

	public var parentNote:Note;
	public var prevNote:Note;

	public var hitByenemy = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var baseAngle:Float = 0;

	public var hitCausesMiss:Bool = false;
	public var doAnimation = true;

	public var colorSwap:ColorSwap;

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

		lastTexture = currentSkin ?? texture;
		final n = dirs[lane];
		frames = Paths.getSparrowAtlas(lastTexture);
		animation.addByPrefix('colored', n + '0', 24);
		animation.addByPrefix('segment', n + ' hold piece0', 24);
		animation.addByPrefix('tail', n + ' hold end0', 24);
		playAnim('colored');

		scale.set(currentNoteScale, currentNoteScale);

		if (isTrail)
		{
			mA = .6;
			alpha = mA;

			playAnim(!isTail ? 'segment' : 'tail');
		}
		else
			earlyHitMult = 1;
		updateHitbox();
		antialiasing = currentBlurring;
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

		if (!hitCausesMiss
			&& !ignoreNote
			&& actorline != null
			&& actorline.autoPlay
			&& time < Conductor.time + (Conductor.sfz * earlyHitMult))
		{
			if ((isTrail && prevNote.hit) || time <= Conductor.time)
				hit = true;
		}
	}

	public function getDistance(actor:Actor, speed:Float = 1):Float
	{
		var dist = (time - Conductor.time) * (0.45 * speed) * (actor?.flipScroll ? -1 : 1);
		return dist + offsetY;
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
		return ((time > Conductor.time - (Conductor.sfz * lateHitMult) && time < Conductor.time + (Conductor.sfz * earlyHitMult)))
			&& !actorline.autoPlay;
	}

	public var ignoreNote = false;

	var clipRecta:FlxRect;

	public function clipToStrumNote(myStrum:Actor)
	{
		var center:Float = myStrum.y + myStrum.height * .5;
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

	public var suffix:String = "";

	override function set_clipRect(rect:FlxRect)
	{
		@:bypassAccessor clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];
		return rect;
	}
}
