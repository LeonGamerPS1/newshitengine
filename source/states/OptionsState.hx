package states;

class OptionsState extends FunkinState
{
	public static var list:Array<String> = ['Gameplay', 'Appearance', 'Performance'];

	var sel = 0;
	var sels:Array<Alphabet>;

	public override function create()
	{
		sels = [];
		add(new FlxSprite().loadGraphic(Paths.getGraphic('menuBG')));
		for (name in list)
		{
			var y = 100;
			var bigchungus:Alphabet = new Alphabet(0, y, name.toUpperCase());
			bigchungus.screenCenter(X);
			bigchungus.y += (160 * sels.length);
			bigchungus.alpha = .5;
			add(bigchungus);
			sels.push(bigchungus);
		}
		addsel();

		super.create();
	}

	public function addsel(add:Int = 0)
	{
		sels[sel].alpha = 0.5;
		sel = FlxMath.wrap(sel + add, 0, sels.length - 1);
		sels[sel].alpha = 1;
		FlxG.sound.play(Paths.getSound('sounds/scrollMenu'));
	}

	var canInteract = true;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (inputSystem.BACK)
			FlxG.switchState(new MainMenu());
		if (!canInteract)
			return;
		if (inputSystem.UI_UP_P)
			addsel(-1);
		if (inputSystem.UI_DOWN_P)
			addsel(1);

		if (inputSystem.ACCEPT)
		{
			FlxG.sound.play(Paths.getSound('sounds/confirmMenu'));
			canInteract = false;
			new FlxTimer().start(0.5, (t) ->
			{
				switch (sels[sel].text.toLowerCase())
				{
					default:
						FlxG.sound.play(Paths.getSound('sounds/cancelMenu'));
						canInteract = true;
					case 'gameplay':
						FlxG.switchState(new states.options.Gameplay());
				}
			});
		}
	}
}
