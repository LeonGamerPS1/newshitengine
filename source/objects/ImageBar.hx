package objects;

import flixel.math.FlxPoint;

class ImageBar extends FlxSpriteGroup
{
	public var fillLeft:FlxSprite;
	public var fillRight:FlxSprite;
	public var overlay:FlxSprite;

	public var percent(get, null):Float;
	public var value(get, default):Float = 0;

	public var max:Float = 100;
	public var min:Float = 0;

	public var rightToLeft:Bool = false;

	var lasser = .0;
	public var center:FlxPoint = FlxPoint.get(0, 0);

	public function new(barSkin:String = 'health', leftColor:FlxColor = FlxColor.LIME, rightColor:FlxColor = FlxColor.RED)
	{
		super();

		overlay = new FlxSprite(0, 0, Paths.getGraphic('ui/bars/$barSkin/overlay'));
		fillLeft = new FlxSprite(0, 0, Paths.getGraphic('ui/bars/$barSkin/fillleft'));
		fillRight = new FlxSprite(0, 0, Paths.getGraphic('ui/bars/$barSkin/fillright'));

		add(fillRight);
		add(fillLeft);
		add(overlay);

		for (spr in members)
		{
			spr.offset.set(0, 0);
			spr.origin.set(0, 0);
		}

		fillLeft.color = leftColor;
		fillRight.color = rightColor;

		fillLeft.clipRect = new FlxRect(0, 0, fillLeft.frameWidth, fillLeft.frameHeight);
	}

	public function setBounds(min:Float = 0, max:Float = 100)
	{
		this.min = min;
		this.max = max;
	}

	function get_percent():Float
	{
		return value / max;
	}

	function get_value():Float
	{
		return FlxMath.bound(value, min, max);
	}

	var lastV:Float = -1;

	override function update(dt:Float)
	{
		super.update(dt);
		if (value != lastV || lasser != angle)
		{
			lasser = angle;
			if (!rightToLeft)
			{
				center.set((fillLeft.width * percent), 0);
				center.rotateByDegrees(angle);
				center.add(x, y);
				fillLeft.clipRect.x = 0;
				fillLeft.clipRect.width = fillLeft.frameWidth * percent;
			}
			else
			{
				center.set((fillLeft.width * (1 - percent)), 0);
				center.rotateByDegrees(angle);
				center.add(x, y);
				var clipWidth:Float = fillLeft.frameWidth * percent;
				fillLeft.clipRect.x = fillLeft.frameWidth - clipWidth;
				fillLeft.clipRect.width = clipWidth;
			}

			fillLeft.clipRect = fillLeft.clipRect;
			lastV = value;
		}
	}
}
