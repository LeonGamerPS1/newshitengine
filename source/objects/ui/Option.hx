package objects.ui;

import backend.ClientPrefs;
import flixel.util.FlxSignal;

enum OptionType
{
	BOOL;
	INT(min:Int, max:Float, increment:Int);
	FLOAT(min:Float, max:Float, increment:Float);
	STRING(options:Array<String>);
	N;
}

class Option extends FlxSpriteGroup
{
	public var saveName:String;
	public var type:OptionType;
	public var value:Dynamic;
	public var basic:FlxBasic;
	public var intenName = ""; // display name
	public var selected:Bool = false;
	public var displayText:Alphabet;

	public var onValChange:FlxTypedSignal<Option->Void> = new FlxTypedSignal<Option->Void>();

	public function new(saveName:String, type:OptionType)
	{
		super();
		this.saveName = saveName;
		this.type = type;
		value = Reflect.getProperty(ClientPrefs.data, saveName);
	}

	public function upload()
	{
		ClientPrefs.setVal(saveName, value);
		onValChange.dispatch(this);
		FlxG.sound.play(Paths.getSound("sounds/scrollMenu"));
	}

	public override function reset(x, y)
	{
		ClientPrefs.setVal(saveName, Reflect.getProperty(ClientPrefs.defaultData, saveName));
		value = Reflect.getProperty(ClientPrefs.defaultData, saveName);
		onValChange.dispatch(this);
	}

	override function destroy()
	{
		basic = null;
		onValChange.removeAll();
		onValChange = null;
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (type == N)
			return;

		// i have no better way of doing this rn :sob:
		switch (type)
		{
			case BOOL:
				if (selected && inputSystem.ACCEPT)
				{
					value = !value;
					upload();
				}
			case INT(min, max, increment):
				if (selected)
				{
					var currentVal:Int = value;
					if (inputSystem.UI_LEFT_P)
					{
						currentVal -= increment;
						value = FlxMath.bound(currentVal, min, max);
						upload();
					}
					else if (inputSystem.UI_RIGHT_P)
					{
						currentVal += increment;
						value = FlxMath.bound(currentVal, min, max);
						upload();
					}
				}

			case FLOAT(min, max, increment):
				if (selected)
				{
					var currentVal:Float = value;
					if (inputSystem.UI_LEFT_P)
						currentVal -= increment;
					else if (inputSystem.UI_RIGHT_P)
						currentVal += increment;
					value = FlxMath.bound(currentVal, min, max);
					upload();
				}
			default: // here so the compiler doesnt nag about Unmatched patterns: FLOAT | INT | STRING
		}
	}
}

class OptionCheckbox extends FunkinSprite
{
	public var option:Option;

	public function new(option:Option)
	{
		super(0, 0);
		this.option = option;
		loadAtlas("checkbox", SPARROW);
		addAnimPrefix("unselected", "Check Box unselected");
		addAnimPrefix("selected", "Check Box selecting animation");

		playAnim("unselected");
		scale.set(0.9, 0.9);
		updateHitbox();
		playAnim(option.value ? "selected" : "unselected");
		option.onValChange.add((option:Option) ->
		{
			playAnim(option.value ? "selected" : "unselected");
		});

		antialiasing = true;
	}

	override function update(elapsed:Float)
	{
		var targetX = option.x + option.displayText?.width + 20;
		var targetY = option.y + (option.displayText?.height / 2 - height / 2);
		if (x != targetX)
			x = targetX;
		if (y != targetY)
			y = targetY;
		super.update(elapsed);
	}
}
