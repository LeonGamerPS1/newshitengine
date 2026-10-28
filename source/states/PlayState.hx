package states;

import backend.Scoring;
import backend.ScriptLoader;
import backend.Song;
import backend.util.MathUtil.Vector3;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxPoint;
import foxlite.FoxScene;
import foxlite.extras.FoxFPSCamera;
import foxlite.flixel.FoxFlxSprite;
import foxlite.loaders.FoxLoaderUtil;
import foxlite.renderer.FoxRenderer;
import modchart.ModchartSystem;
import modding.scripts.BaseScript;
import objects.Actor;
import objects.ActorLine;
import objects.Note;
import objects.gameplay.BaseStage;
import objects.gameplay.Character;
import objects.gameplay.stages.Week1;
import objects.ui.HealthBar;
import objects.ui.HealthIcon;
import openfl.system.Capabilities;

enum abstract CharType(String) from String to String
{
	var DAD = 'dad';
	var GF = 'gf';
	var BF = 'bf';
}

class PlayState extends FunkinState
{
	public static var instance:PlayState;

	public var actorLines:Array<ActorLine> = [];
	public var enemyLine:ActorLine;
	public var playerLine:ActorLine;

	public var inst:FlxSound;
	public var voices:FlxSound;

	public static var song:SwagSong;

	public var startedCountdown = false;
	public var startedSong = false;

	public var camUnderlay:FlxCamera;
	public var camHUD:FlxCamera;
	public var hud:FlxGroup;
	public var defaultCamZoom:Float = 1;

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

	public var scripts:Array<BaseScript> = [];

	// for scripts and stuff to globally share variables inbetween if users split stuff into multiple scripts
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var modManager:ModchartSystem;

	public var downscroll:Bool = false;

	public var characterChangeMapDad:Map<String, Character>;
	public var characterChangeMapGF:Map<String, Character>;
	public var characterChangeMapBF:Map<String, Character>;

	override public function create()
	{
		super.create();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		characterChangeMapDad = new Map<String, Character>();
		characterChangeMapGF = new Map<String, Character>();
		characterChangeMapBF = new Map<String, Character>();

		instance = this;
		modManager = new ModchartSystem();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		camUnderlay = new FlxCamera();
		camUnderlay.bgColor.alpha = 0;

		FlxG.camera.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.add(camUnderlay, false);

		FlxG.cameras.add(camHUD, false);

		hud = new FlxGroup();
		hud.cameras = [camHUD];
		add(hud);

		song ??= Song.loadFromJson('hard', 'careless');
		Conductor.reset();
		Conductor.bpm = song.bpm;
		Conductor.time = -Conductor.beatLength * 5;
		Conductor.onBeat.add(onBeat);
		Conductor.onMeasure.add(onMeasure);
		Conductor.onStep.add(onStepHit);

		loadScript(Paths.getPath('data/stages/${song.stage ?? 'stage'}.hx'));
		loadScripts(Paths.readAssetsDirectoryFromLibrary('data/scripts', 'TEXT', 'hx'));
		loadScripts(Paths.readAssetsDirectoryFromLibrary('songs/${song.folder}/scripts', 'TEXT', 'hx'));
		set('bpm', Conductor.bpm);

		var instPath = 'songs/${song.folder}/Inst';
		inst = FlxG.sound.list.add(new FlxSound());
		inst.loadEmbedded(Paths.getSound(instPath, true), false);

		var instPath = 'songs/${song.folder}/Voices';
		voices = FlxG.sound.list.add(new FlxSound());

		voices.loadEmbedded(Paths.getSound(instPath, true), false);

		call('onCreate');
		initStage();
		initChars();

		set('bpm', Conductor.bpm);

		stage.onCreatePost();

		enemyLine = addActorLine(FlxG.width * .25, !downscroll ? 50 : FlxG.height - 150);
		enemyLine.characters.push(dad);

		playerLine = addActorLine(FlxG.width * .75, enemyLine.startY);
		playerLine.autoPlay = false;
		playerLine.characters.push(bf);

		call('onStageCreatePost', [song.stage ?? 'stage']);

		for (sL in actorLines)
		{
			sL.hitSignal.add(hitNote);
			sL.missSignal.add(miss);
			sL.noteMissSignal.add((n) ->
			{
				call('onNoteMiss', [n]);
			});
		}

		healthBar = new HealthBar();
		healthBar.screenCenter(X);
		healthBar.y = !downscroll ? FlxG.height * 0.89 + 9 : FlxG.height * 0.12;
		healthBar.y -= healthBar.overlay.height / 2;
		hud.add(healthBar);

		iconP2 = new HealthIcon(dad.json.icon);
		iconP2.baseScale = dad.json.iconScale ?? 1;

		iconP1 = new HealthIcon(bf.json.icon, true);
		iconP1.baseScale = bf.json.iconScale ?? 1;

		hud.add(iconP1);
		hud.add(iconP2);

		scoreTxt = new FlxText();
		scoreTxt.setFormat(Paths.getFont('vcr'), 16);
		hud.add(scoreTxt);

		focusOnChar(bf);
		var currentBPM = song.bpm;
		var seclength:Float = (60000 / currentBPM) * 4;
		var sectionStartTime:Float = 0;

		Conductor.addTimeChangeAt(0, currentBPM);

		var noteTypesloaded = [''];
		for (section in song.notes)
		{
			if (section.changeBPM && section.bpm != currentBPM)
			{
				currentBPM = section.bpm;

				seclength = (60000 / currentBPM) * 4;

				Conductor.addTimeChangeAt(sectionStartTime, currentBPM);
			}
			else
			{
				var beatsInSec:Float = 4;
				seclength = (60000 / currentBPM) * beatsInSec;
			}

			var steplength = seclength / 16;

			for (note in section.sectionNotes)
			{
				var noteTime:Float = note[0];
				var dir:Int = note[1];
				var length:Float = (note[2] is String) ? 0.0 : note[2];
				var type = Std.string(note[3] ?? '');

				if (!noteTypesloaded.contains(type))
				{
					loadScript('data/notetypes/$type.hx');
					set('bpm', Conductor.bpm);
					noteTypesloaded.push(type);
				}

				var isPlayer = section.mustHitSection;
				if (dir > 3)
					isPlayer = !section.mustHitSection;

				var targetActorline:ActorLine = isPlayer ? playerLine : enemyLine;
				call('onPreNoteCreate', [noteTime, dir % 4, length, type, isPlayer, false, false, targetActorline]);
				var newNote = targetActorline.makeNote(noteTime, dir % 4, length, type);
				newNote.seglength = steplength;
				call('onNoteCreate', [newNote, targetActorline]);

				if (length > 0)
				{
					final holds = Math.floor(length / steplength);

					for (i in 0...holds)
					{
						final noteTime = noteTime + (steplength * i) + (steplength / 2);
						call('onPreNoteCreate', [noteTime, dir % 4, length, type, isPlayer, true, i == holds - 1, targetActorline]);
						var hold = targetActorline.makeHoldNote(noteTime, newNote.lane, steplength, type, i == holds - 1);
						hold.parentNote = newNote;

						call('onNoteSustainCreate', [hold, targetActorline]);
						call('onNoteCreate', [hold, targetActorline]);
					}
				}
			}

			sectionStartTime += seclength;
		}

		Conductor.mapBPMChanges();

		playerLine.sortPremade();
		enemyLine.sortPremade();

		var id = 0;
		var evilnotes = 0;
		for (strumline in actorLines)
		{
			for (note in strumline.unspawnNotes)
			{
				for (evilnote in strumline.unspawnNotes)
				{
					if (note != evilnote
						&& Math.abs(note.time - evilnote.time) < 3
						&& evilnote.isTrail == note.isTrail
						&& note.lane == evilnote.lane)
					{
						evilnotes++;
						evilnote.destroy();
						strumline.unspawnNotes.remove(evilnote);
					}
				}
			}
		}
		trace('found like $evilnotes notes evilized');
		enemyLine.speed = playerLine.speed = song.speed;
		FlxG.camera.follow(camtracker, LOCKON, 0.05 * stageJSON.camera_speed);
		startedCountdown = true;

		call('onCreatePost');
		trace(scripts);
	}

	public var stageJSON:StageFile;
	public var daddyCamOffset = [0.0, 0.0];
	public var bfCamOffset = [0.0, 0.0];

	function loadScript(s:String)
	{
		var s = ScriptLoader.loadScript(s);
		if (s == null || s.dummy)
			return;
		scripts.push(s);
	}

	function loadScripts(s:Array<String>)
	{
		for (script in ScriptLoader.loadScripts(s))
			scripts.push(script);
	}

	public function precacheCharacter(charname:String, type:CharType)
	{
		var map = getPrecacheMapChar(type);
		if (!map.exists(charname))
		{
			map.set(charname, new Character(0, 0, charname, type == BF));
		}
	}

	public function changeCharacter(charname:String, type:CharType)
	{
		var map = getPrecacheMapChar(type);
		if (!map.exists(charname))
			precacheCharacter(charname, type);

		var charToChange = dad;
		var newchar = map.get(charname);

		if (type == GF)
			charToChange = gf;
		else if (type == BF)
			charToChange = bf;

		var shitwasin = [];
		for (strumline in actorLines)
			if (strumline.characters.contains(charToChange))
			{
				strumline.characters.remove(charToChange);
				shitwasin.push(strumline);
			}

		newchar.scrollFactor.copyFrom(charToChange.scrollFactor);
		for (s in shitwasin)
			s.characters.push(newchar);

		var position = dadPosition;
		if (type == GF)
			position = gfPosition;
		if (type == BF)
			position = boyfriendPosition;

		dadLayer.remove(charToChange, true);
		gfLayer.remove(charToChange, true);
		boyfriendLayer.remove(charToChange, true);
		charToChange.destroy();

		if (type == GF)
		{
			gf = newchar;
			gfLayer.insert(0, newchar);
		}
		else if (type == BF)
		{
			bf = newchar;
			boyfriendLayer.insert(0, newchar);
		}
		else if (type == DAD)
		{
			dad = newchar;
			dadLayer.insert(0, newchar);
		}
		charToChange = null;

		newchar.setPosition(position.x + newchar.json.pos_offset[0], position.y + newchar.json.pos_offset[1]);
		focusOnChar(section.mustHitSection ? bf : dad);
	}

	public function getPrecacheMapChar(type:CharType):Map<String, Character>
	{
		return type == DAD ? characterChangeMapDad : (type == BF ? characterChangeMapBF : characterChangeMapGF);
	}

	public function call(fn:String, ?args:Array<Dynamic>):Dynamic
	{
		var ret:Dynamic = null;

		for (shi in scripts)
		{
			var ret_s = shi.call(fn, args);
			if (ret_s != null)
				ret = ret_s;
		}
		return ret;
	}

	public function set(val:String, valVal:Dynamic)
	{
		for (shi in scripts)
		{
			shi.setVariable(val, valVal);
		}
	}

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
		add(stage);
		stage.onCreate();

		call('onStageCreate', [stage1lol]);
	}

	var scene:FoxScene;
	var cam:FoxFPSCamera;

	var lastFollowedChar:Character;

	public function focusOnChar(char:Character)
	{
		lastFollowedChar = char;
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
		var line:ActorLine = cast hud.add(new ActorLine(x, y, downscroll));
		actorLines.push(line);
		return line;
	}

	public var score:Int = 0;
	public var misses:Int = 0;
	public var accuracy:Float = 0.0;

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.F1)
		{
			var win = FlxG.stage.window;
			FlxTween.tween(win, {
				x: 0,
				y: 0,
				width: Capabilities.screenResolutionX,
				height: Capabilities.screenResolutionY
			}, 0.5);
		}
		call('onUpdate', [elapsed]);
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		if (healthBar.value != health)
		{
			healthBar.value = health;
			health = healthBar.value;
			updateIcon(iconP1, healthBar.percent, true);
			updateIcon(iconP2, healthBar.percent);
		}

		final accuracye = FlxMath.roundDecimal(accuracy, 2);
		scoreTxt.text = 'Score:$score    Misses:$misses    Accuracy:$accuracye%';
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
		iconP1.lerp();
		iconP2.lerp();

		super.update(elapsed);
		modManager.update(elapsed);

		iconP1.setPosition(healthBar.center.x - 26, healthBar.center.y - iconP1.frameHeight * iconP1.baseScale / 2);
		iconP2.setPosition(healthBar.center.x
			- (iconP2.frameWidth * iconP2.scale.x)
			+ (iconP2.frameWidth * iconP2.baseScale / 4),
			healthBar.center.y
			- iconP2.frameHeight * iconP2.baseScale / 2);
		call('onUpdatePost', [elapsed]);

		if (health <= healthBar.min || FlxG.keys.justPressed.R)
		{
			inst.pause();
			voices.pause();
			persistentDraw = false;
			persistentUpdate = false;

			openSubState(new GameoverState());
		}
	}

	function startSong()
	{
		startedSong = true;
		inst.play();
		voices.play();
		call('onStartSong');
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

		set('curStep', step);
		call('onStepHit', [step]);
	}

	public function onBeat(b:Int)
	{
		if (b % zoomInterval == 0)
			zoom();
		iconP1.bump();
		iconP2.bump();
		stage.onBeatHit(b);

		set('bpm', Conductor.bpm);
		set('curBeat', b);
		call('onBeatHit', [b]);
	}

	var section:SwagSection;

	public function onMeasure(sections:Int)
	{
		var section = song.notes[sections];
		stage.onSectionHit(sections);
		this.section = section;
		if (section != null)
		{
			focusOnChar(section.mustHitSection ? bf : dad);
			call('onCameraMove', [lastFollowedChar, !lastFollowedChar.player]); // character, is the dad  or not
		}

		set('curSection', sections);
		call('onSectionHit', [sections]);
	}

	public var health:Float = 1;

	public var earnedAccuracyPoints:Float = 0.0;
	public var maxAccuracyPoints:Float = 0.0;

	public function hitNote(note:Note)
	{
		if (!note.actorline.autoPlay)
		{
			health += 0.023;

			if (!note.isTrail)
			{
				var timing:Float = Math.abs(Conductor.time - note.time);

				note.rating = Scoring.judgeNote(timing);
				score += Scoring.scoreNote(timing);
				accuracy = ((earnedAccuracyPoints += (timing <= 45 ? 100 : timing <= 90 ? 75 : timing <= 135 ? 40 : 20)) / (maxAccuracyPoints += 100)) * 100;

				if (note.rating == 'sick')
					note.actorline.spawnSplashOnStrum(note.actorline.actors.members[note.lane]);
			}
		}
		call('hitNote', [note, note.actorline.autoPlay]);
	}

	public function miss(dir:Int, isSustain:Bool = false)
	{
		misses++;
		health -= 0.05;
		call('missDirection', [dir]);

		if (!isSustain)
			accuracy = (earnedAccuracyPoints / (maxAccuracyPoints += 100)) * 100;
		score += Scoring.getMissScore();
	}

	public static function updateIcon(healthI:HealthIcon, perc:Float = 0, player:Bool = false)
	{
		var hframes = healthI.animation.numFrames;
		if (hframes == 0 || hframes == 1 || healthI.animation.curAnim == null) // missing animation or really just one frame
			return;
		if (player)
		{
			if (perc <= 0.2)
				healthI.animation.curAnim.curFrame = 1;
			else if (perc >= 0.8 && hframes > 2)
				healthI.animation.curAnim.curFrame = 2;
			else
				healthI.animation.curAnim.curFrame = 0;
		}
		else
		{
			if (perc >= 0.8)
				healthI.animation.curAnim.curFrame = 1;
			else if (perc <= 0.2 && hframes > 2)
				healthI.animation.curAnim.curFrame = 2;
			else
				healthI.animation.curAnim.curFrame = 0;
		}
	}

	override function destroy()
	{
		FlxTimer.globalManager.clear();
		super.destroy();
	}
}
