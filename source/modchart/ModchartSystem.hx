package modchart;

import modchart.Modifier;
import objects.ActorLine;
import objects.Note;
import openfl.geom.ColorTransform;

class ModchartSystem
{
	/**
	 * One arrow width in pixels. 100% on a move modifier = one arrow width.
	 * Point this at your real note width (e.g. Note.swagWidth) if you have one.
	 */
	public static var ARROW_SIZE:Float = 112;

	private static var modifierClassMap:Map<String, Class<Dynamic>> = [
		'Dummy' => Modifier,
		'moveX' => MoveX,
		'moveY' => MoveY,
		'zigzag' => ZigZag,
		'stealth' => Stealth
	];

	public static var sys:ModchartSystem;

	public var modifiersValmap:Map<Int, Map<String, Float>>;
	public var modifiersOrSmth:Map<Int, Map<String, Modifier>>;

	public var lines:Array<ActorLine>;
	public var players:Int = 2;

	// scratch params, reset for every strum before the modifiers touch it
	private var params:VisualParams = {
		x: 0,
		y: 0,
		angle: 0,
		scaleX: 1,
		scaleY: 1,
		alpha: 1,
		color: new ColorTransform()
	};

	// modifiers that are currently running for the player being processed
	private var active:Array<Modifier> = [];

	public function new(players:Int = 2)
	{
		sys = this;
		this.players = players;
		this.lines = PlayState.instance.actorLines;
		modifiersValmap = new Map<Int, Map<String, Float>>();
		modifiersOrSmth = new Map<Int, Map<String, Modifier>>();
		for (i in 0...players)
		{
			modifiersOrSmth.set(i, new Map<String, Modifier>());
			modifiersValmap.set(i, new Map<String, Float>());
		}
	}

	/**
	 * Creates the modifier for one player, or for every player if player == -1.
	 */
	public function addModifier(name:String, player:Int = -1)
	{
		if (player == -1)
		{
			for (i in 0...players)
				addModifier(name, i);
			return;
		}

		var cls = modifierClassMap.get(name);
		if (cls == null)
		{
			trace('modifier $name does not exist lol');
			return;
		}
		if (!modifiersValmap.exists(player))
		{
			trace('player $player does not exist (players: $players)');
			return;
		}

		// keep a value that was already set before the modifier got added
		if (!modifiersValmap.get(player).exists(name))
			modifiersValmap.get(player).set(name, 0);

		var instance:Modifier = Type.createInstance(cls, [this]);
		instance.name = name;
		instance.player = player;
		modifiersOrSmth.get(player).set(name, instance);
	}

	public function registerModifierClass(name:String, cls:Class<Dynamic>)
	{
		if (modifierClassMap.get(name) == null)
			modifierClassMap.set(name, cls);
		else
			trace('classmod $name already exists as ${modifierClassMap.get(name)}, cannot overwrite with ($name | $cls)');
	}

	public function getPercent(name:String, player:Int = 0):Float
	{
		var vals = modifiersValmap.get(player);
		if (vals == null)
			return 0;
		return vals.get(name) ?? 0;
	}

	public function setPercent(name:String, val:Float = 0, player:Int = -1)
	{
		if (player == -1)
		{
			for (i in modifiersValmap.keyValueIterator())
				i.value.set(name, val);
			return;
		}

		var vals = modifiersValmap.get(player);
		if (vals == null)
		{
			trace('player $player does not exist (players: $players)');
			return;
		}
		vals.set(name, val);
	}

	private inline function resetParams()
	{
		params.x = 0;
		params.y = 0;
		params.angle = 0;
		params.scaleX = 1;
		params.scaleY = 1;
		params.alpha = 1;
		params.color = new ColorTransform();
	}

	public function update(elapsed:Float)
	{
		if (lines == null)
			return;

		for (playerID in 0...players)
		{
			if (playerID >= lines.length || lines[playerID] == null)
				continue;

			var line = lines[playerID];

			// collect the running modifiers once per frame instead of once per object
			active.resize(0);
			for (mod in modifiersOrSmth.get(playerID))
			{
				if (mod.shouldRun())
				{
					mod.update(elapsed);
					active.push(mod);
				}
			}

			var strums = line.actors.members;

			for (strum in strums)
			{
				if (strum == null)
					continue;

				// start from zero every frame so a modifier that stops running
				// (percent back to 0) automatically drops its offset again
				resetParams();

				for (mod in active)
					mod.processVisuals(params, false, null, strum);

				strum.renderOffset.set(params.x, params.y);
			}

			for (note in line.notes.members)
			{
				if (note == null)
					continue;

				// the strum this note belongs to (its column), so modifiers can read it
				var strum = (note.lane >= 0 && note.lane < strums.length) ? strums[note.lane] : null;

				resetParams();

				for (mod in active)
					mod.processVisuals(params, true, note, strum);

				note.renderOffset.set(params.x, params.y);
				note.angle = params.angle + note.baseAngle;

				// alpha is multiplied onto whatever the engine set this frame, so the engine must
				// rewrite note.alpha every frame BEFORE this runs, otherwise it would compound.
				// Call update() at the END of PlayState.update, after the notes were updated.
				if (params.alpha != 1)
					note.alpha *= params.alpha;
			}
		}
	}
}
