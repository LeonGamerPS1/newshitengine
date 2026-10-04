package states;

import backend.Song;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxPoint;
import foxlite.FoxScene;
import foxlite.extras.FoxFPSCamera;
import foxlite.flixel.FoxFlxSprite;
import foxlite.loaders.FoxLoaderUtil;
import foxlite.renderer.FoxRenderer;
import objects.Actor;
import objects.ActorLine;
import objects.Note;
import objects.gameplay.BaseStage;
import objects.gameplay.Character;
import objects.gameplay.stages.Week1;
import objects.ui.HealthBar;
import objects.ui.HealthIcon;

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

	public var healthBar:HealthBar;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	// enemy
	public var dadLayer:FlxGroup;
	public var dadPosition:FlxPoint = FlxPoint.get(100, 100);

	// gf
	public var gfLayer:FlxGroup;
	public var gfPosition:FlxPoint = FlxPoint.get(400, 130);

	// player
	public var boyfriendLayer:FlxGroup;
	public var boyfriendPosition:FlxPoint = FlxPoint.get(770, 100);

	public var dad:Character;
	public var gf:Character;
	public var bf:Character;

	public var camtracker:FlxObject = new FlxObject(0, 0, 1, 1);

	public var stage:BaseStage;
	public var scoreTxt:FlxText;

	override public function create()
	{
		super.create();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.camera.bgColor = FlxColor.GRAY;
		FlxG.cameras.add(camHUD, false);

		hud = new FlxGroup();
		hud.cameras = [camHUD];
		add(hud);

		song ??= Song.loadFromJson('hard', 'ice-roses');
		Conductor.reset();
		Conductor.bpm = song.bpm;
		Conductor.time = -Conductor.beatLength * 5;
		Conductor.onBeat.add(onBeat);
		Conductor.onMeasure.add(onMeasure);
		Conductor.onStep.add(onStepHit);

		var instPath = 'songs/${song.folder}/Inst';
		inst = FlxG.sound.list.add(new FlxSound());
		inst.load(Paths.getSound(instPath, true), false);

		var instPath = 'songs/${song.folder}/Voices';
		voices = FlxG.sound.list.add(new FlxSound());
		voices.load(Paths.getSound(instPath, true), false);

		var time = .0;
		var seclength = Conductor.measureLength;
		var bpm = song.bpm;

		initStage();
		initChars();
		stage.onCreatePost();

		enemyLine = addActorLine(FlxG.width * .25, 50);
		enemyLine.characters.push(dad);

		playerLine = addActorLine(FlxG.width * .75, 50);
		playerLine.autoPlay = false;
		playerLine.characters.push(bf);

		for(sL in actorLines)
		{
			sL.hitSignal.add(hitNote);
			sL.missSignal.add(miss);
		}

		healthBar = new HealthBar();
		healthBar.screenCenter(X);
		healthBar.y = FlxG.height * 0.89 + 9;
		healthBar.y -= healthBar.overlay.height / 2;
		hud.add(healthBar);

		iconP2 = new HealthIcon(dad.json.icon);
		iconP2.baseScale = dad.json.iconScale ?? 1;

		iconP1 = new HealthIcon(bf.json.icon, true);
		iconP1.baseScale = bf.json.iconScale ?? 1;

		hud.add(iconP1);
		hud.add(iconP2);

		scoreTxt = new FlxText();
		scoreTxt.setFormat(Paths.getFont('vcr'), 15);
		hud.add(scoreTxt);

		for (section in song.notes)
		{
			if (section.changeBPM)
			{
				bpm = section.bpm;
				seclength = (bpm / 60000) * 4;
				Conductor.addTimeChangeAt(time, bpm);
			}
			time += seclength;

			for (note in section.sectionNotes)
			{
				var time:Float = note[0];
				var dir:Int = note[1];
				var length:Float = note[2] is String ? 0.0 : note[2];
				var type = note[3] ?? '';

				var isPlayer = section.mustHitSection;
				if (dir > 3)
					isPlayer = !section.mustHitSection;

				var targetActorline:ActorLine = isPlayer ? playerLine : enemyLine;
				var note = targetActorline.makeNote(time, dir % 4, length, type);

				var steplength = seclength / 16;
				if (length > 0)
				{
					var holds = Math.floor(length / steplength);

					for (i in 0...holds)
					{
						var hold = targetActorline.makeHoldNote(time + (steplength * i) + (steplength / 2), dir % 4, steplength, type, i == holds - 1);
						hold.parentNote = note;
					}
				}
			}
		}
		playerLine.sortPremade();
		enemyLine.sortPremade();

		enemyLine.speed = playerLine.speed = song.speed;
		FlxG.camera.follow(camtracker, LOCKON, 0.05 * stageJSON.camera_speed);
		startedCountdown = true;

		/*
			FoxRenderer.initLibs();
			FoxLoaderUtil.initPathClass(Paths);

			// Scene
			scene = new FoxScene(FlxG.width, FlxG.height);
			scene.scrollFactor.set(0, 0);
			add(scene);

			// Camera
			cam = new FoxFPSCamera();
			cam.bgColor = FlxColor.PURPLE;

			// Add our camera to the scene
			scene.foxCameras.push(cam);
			var grid:FlxSprite = new FlxSprite(0,0,FlxGridOverlay.createGrid(50,50,1280,720,true,0xFFFFFFFF,0xFF807D7D));
			insert(0,grid);

			var fx:FoxFlxSprite = new FoxFlxSprite(grid);
			fx.rotation.x = 45;
			scene.add(fx);
		 */
	}

	public var stageJSON:StageFile;
	public var daddyCamOffset = [0.0, 0.0];
	public var bfCamOffset = [0.0, 0.0];

	function initStage()
	{
		final stage1lol = song.stage ?? 'stage';

		var path = 'data/stages/$stage1lol.json';
		try
		{
			stageJSON = cast Json.parse(OpenFLAssets.getText(Paths.getPath(path)));
		}
		catch (e:Dynamic)
		{
			stage = new BaseStage();
			stageJSON = cast Json.parse(OpenFLAssets.getText(Paths.getPath('data/stages/stage.json')));
		}
		daddyCamOffset = stageJSON.camera_opponent;
		bfCamOffset = stageJSON.camera_boyfriend;
		defaultCamZoom = stageJSON.defaultZoom;

		dadPosition.set(stageJSON.opponent[0], stageJSON.opponent[1]);
		gfPosition.set(stageJSON.girlfriend[0], stageJSON.girlfriend[1]);
		boyfriendPosition.set(stageJSON.boyfriend[0], stageJSON.boyfriend[1]);

		switch (stage1lol)
		{
			default:
				stage = new BaseStage();
			case 'stage':
				stage = new Week1();
		}

		stage.onCreate();
	}

	var scene:FoxScene;
	var cam:FoxFPSCamera;

	public function focusOnChar(char:Character)
	{
		if (char.player)
		{
			camtracker.setPosition(char.getMidpoint().x - 100, char.getMidpoint().y - 100);
			camtracker.x -= char.json.cam_offset[0] + bfCamOffset[0];
			camtracker.y += char.json.cam_offset[1] + bfCamOffset[0];
		}
		else
		{
			camtracker.setPosition(char.getMidpoint().x + 160, char.getMidpoint().y - 100);
			camtracker.x += char.json.cam_offset[0] + daddyCamOffset[0];
			camtracker.y += char.json.cam_offset[1] + daddyCamOffset[1];
		}
	}

	function initChars()
	{
		gfLayer = new FlxGroup();
		dadLayer = new FlxGroup();
		boyfriendLayer = new FlxGroup();

		add(gfLayer);
		add(dadLayer);
		add(boyfriendLayer);

		if (stageJSON.hide_girlfriend)
			gfLayer.kill();
		if (song.player2 == song.gfVersion)
		{
			dadPosition.copyFrom(gfPosition);
			gfLayer.kill();
		}
		dad = new Character(0, 0, song.player2);
		dad.setPosition(dadPosition.x, dadPosition.y);
		dad.setPosition(dad.x + dad.json.pos_offset[0], dad.y + dad.json.pos_offset[1]);

		gf = new Character(0, 0, song.gfVersion);
		gf.setPosition(gfPosition.x, gfPosition.y);
		gf.setPosition(gf.x + gf.json.pos_offset[0], gf.y + gf.json.pos_offset[1]);

		bf = new Character(0, 0, song.player1, true);
		bf.setPosition(boyfriendPosition.x, boyfriendPosition.y);
		bf.setPosition(bf.x + bf.json.pos_offset[0], bf.y + bf.json.pos_offset[1]);

		gfLayer.add(gf);
		dadLayer.add(dad);
		boyfriendLayer.add(bf);
	}

	public function addActorLine(x:Float = 0, y:Float = 0):ActorLine
	{
		var line:ActorLine = cast hud.add(new ActorLine(x, y));
		actorLines.push(line);
		return line;
	}

	public var score:Int = 0;
	public var misses:Int = 0;
	public var accuracy:Int = 0;

	override public function update(elapsed:Float)
	{
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		if(healthBar.value != health) {
			healthBar.value = health;
			health = healthBar.value;
		}

		scoreTxt.text = 'Score:$score    Misses:$misses    Accuracy:$accuracy';
		scoreTxt.y = healthBar.y + healthBar.height;
		scoreTxt.screenCenter(X);
		if (startedCountdown && !startedSong)
		{
			Conductor.time += elapsed * 1000;
			if (Conductor.time >= 0)
				startSong();
		}
		if (startedSong)
			Conductor.time = inst.time;

		super.update(elapsed);
		iconP1.lerp();
		iconP2.lerp();

		iconP1.setPosition(healthBar.center.x - 26, healthBar.center.y - (iconP1.frameHeight / 2 * iconP1.baseScale));
		iconP2.setPosition(healthBar.center.x
			- (iconP2.frameWidth * iconP2.scale.x)
			+ (iconP2.frameWidth * iconP2.baseScale / 4),
			healthBar.center.y
			- (iconP2.frameHeight / 2 * iconP2.baseScale));
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

	public function onStepHit(step:Int)
	{
		stage.onStepHit(step);
	}

	public function onBeat(b)
	{
		if (b % zoomInterval == 0)
			zoom();
		iconP1.bump();
		iconP2.bump();
		stage.onBeatHit(b);
	}

	public function onMeasure(sections:Int)
	{
		var section = song.notes[sections];
		stage.onSectionHit(sections);
		if (section != null)
		{
			focusOnChar(section.mustHitSection ? bf : dad);
		}
	}

	public var health:Float = 1;

	public function hitNote(note:Note)
	{
		if (!note.actorline.autoPlay)
			health += 0.023;
	}

	public function miss(dir:Int)
	{
		health -= 0.05;
	}
}
