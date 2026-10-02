package states;

import backend.Song;
import objects.Actor;
import objects.ActorLine;

class PlayState extends FlxState
{
	public var actorLines:Array<ActorLine> = [];
	public var enemyLine:ActorLine;
	public var playerLine:ActorLine;

	public var inst:FlxSound;
	public var voices:FlxSound;

	public static var song:SwagSong;

	public var startedCountdown = false;
	public var startedSong = false;

	public var camHUD:FlxCamera;
	public var hud:FlxGroup;
	public var defaultCamZoom(default, null):Float = 1;

	override public function create()
	{
		super.create();
		camHUD = new FlxCamera();
		FlxG.cameras.add(camHUD, false);

		hud = new FlxGroup();
		hud.cameras = [camHUD];
		add(hud);

		song ??= Song.loadFromJson('hard', 'careless');
		Conductor.reset();
		Conductor.bpm = song.bpm;
		Conductor.time = -Conductor.beatLength * 5;
		Conductor.onBeat.add(onBeat);

		var instPath = 'songs/careless/Inst';
		inst = FlxG.sound.list.add(new FlxSound());
		inst.load(Paths.getSound(instPath, true), false);

		var instPath = 'songs/careless/Voices';
		voices = FlxG.sound.list.add(new FlxSound());
		voices.load(Paths.getSound(instPath, true), false);

		var time = .0;
		var seclength = Conductor.measureLength;
		var bpm = song.bpm;

		enemyLine = addActorLine(FlxG.width * .25, 50);
		playerLine = addActorLine(FlxG.width * .75, 50);

		startedCountdown = true;
	}

	public function addActorLine(x:Float = 0, y:Float = 0):ActorLine
	{
		var line:ActorLine = cast hud.add(new ActorLine(x, y));
		actorLines.push(line);
		return line;
	}

	override public function update(elapsed:Float)
	{
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		if (startedCountdown && !startedSong)
		{
			Conductor.time += elapsed * 1000;
			if (Conductor.time >= 0)
				startSong();
		}
		if (startedSong)
			Conductor.time = inst.time;
		super.update(elapsed);
	}

	function startSong()
	{
		startedSong = true;
		inst.play();
		voices.play();
	}

	public function zoom()
	{
		FlxG.camera.zoom += 0.015;
		camHUD.zoom += 0.03;
	}

	public var zoomInterval:Int = 4;

	public function onBeat(b:Float)
	{
		trace(b);
		if (b % zoomInterval == 0)
			zoom();
	}
}
