package states;

import flixel.effects.FlxFlicker;

class MainMenu extends FunkinState
{
	static var list:Array<String> = ['story_mode', 'freeplay', 'options'];

	var currentItem:Int = 0;
	var items:Array<FlxSprite>;
	var bg:FlxSprite;
	var camfollow:FlxObject;

	override function create()
	{
		super.create();
		items = [];
		bg = new FlxSprite(0, 0, Paths.getGraphic('menuBG'));
		bg.scrollFactor.set();
		add(bg);

		camfollow = new FlxObject(0, 0, 1, 1);
		add(camfollow);
		FlxG.camera.follow(camfollow, LOCKON, 0.06);

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.getSound('music/freakyMenu', true));
		FlxG.sound.music.persist = true;
		for (itemsa in list)
		{
			var offset:Float = 108 - (Math.max(list.length, 4) - 4) * 80;
			var item = new FlxSprite(0, (items.length * 140) + offset);
			item.frames = Paths.getSparrowAtlas('mainmenu/menu_$itemsa');
			item.animation.addByPrefix('basic', itemsa + ' basic', 24);
			item.animation.addByPrefix('white', itemsa + ' white');
			item.animation.play('basic');
			item.updateHitbox();
			item.screenCenter(X);
			item.antialiasing = true;
			add(item);
			items.push(item);

			var scr:Float = (list.length - 4) * 0.135;
			if (list.length < 6)
				scr = 0;
			item.scrollFactor.set(0, scr);
		}
		changeSelect(0);
	}

	function changeSelect(add = 0)
	{
		items[currentItem].animation.play('basic');
		items[currentItem].updateHitbox();
		items[currentItem].screenCenter(X);
		currentItem = FlxMath.wrap(currentItem + add, 0, items.length - 1);
		items[currentItem].animation.play('white');
		items[currentItem].updateHitbox();
		items[currentItem].screenCenter(X);

		FlxG.sound.play(Paths.getSound('sounds/scrollMenu'));
	}

	var selectedSmth:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (selectedSmth)
			return;
		if (inputSystem.UI_DOWN_P)
			changeSelect(1);
		if (inputSystem.UI_UP_P)
			changeSelect(-1);

		if (inputSystem.ACCEPT)
		{
			FlxFlicker.flicker(items[currentItem], 1, 0.1, true, true, (f) ->
			{
				switch (list[currentItem])
				{
					default:
						selectedSmth = false;
					case 'freeplay':
						Main.switchState(new PlayState());
				}
			});
		}
	}
}
