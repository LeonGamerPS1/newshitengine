package states;

import objects.gameplay.Character;

class GameoverState extends FlxSubState
{
	public static var deathChar:String = 'bf-dead';

	public static var bfPos:FlxPoint;

	public static var deathSnd:String = 'sounds/fnf_loss_sfx';
	public static var deathMus:String = 'music/gameOver';
	public static var deathMusEnd:String = 'music/gameOverEnd';

	public var snd:FlxSound;
	public var char:Character;
	public var camFollow:FlxObject;

	public static var prevFollow:FlxPoint;

	public override function create()
	{
		prevFollow ??= FlxPoint.get(0, 0);
		var boyfriend = PlayState.instance.bf;
		super.create();
		camFollow = new FlxObject(0, 0, 1, 1);
		

		prevFollow.put();
		prevFollow = null;

		snd = FlxG.sound.play(Paths.getSound(deathSnd, true));

		char = new Character(PlayState.instance.bf.x, PlayState.instance.bf.y, deathChar, true);
		char.playAnim('firstDeath');
		add(char);

		char.x += char.json.pos_offset[0] - PlayState.instance.bf.json.pos_offset[0];
		char.y += char.json.pos_offset[1] - PlayState.instance.bf.json.pos_offset[1];

		camFollow.setPosition(char.getMidpoint().x - 100, char.getMidpoint().y - 100);
		camFollow.x -= char.json.cam_offset[0];
		camFollow.y += char.json.cam_offset[1];
		add(camFollow);

		

		FlxG.camera.follow(camFollow, LOCKON, 0.007);

		new FlxTimer().start(2.4, (t) ->
		{
			if (fart)
				return;
			snd = FlxG.sound.play(Paths.getSound(deathMus, true), 1, true);
			char.playAnim('deathLoop');
		});
	}

	var fart = false;

	override function update(_:Float)
	{
		super.update(_);

		if (inputSystem.ACCEPT && !fart)
		{
			fart = true;
			snd.stop();
			snd = FlxG.sound.play(Paths.getSound(deathMusEnd, true));
			char.playAnim('deathConfirm');
			FlxG.camera.fade(FlxColor.BLACK, 4, false, function()
			{
				FlxG.switchState(new PlayState());
			});
		}
	}
}
