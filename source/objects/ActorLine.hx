package objects;

import flixel.util.FlxSignal.FlxTypedSignal;
import objects.gameplay.Character;

class ActorLine extends FlxGroup
{
	public var actors:FlxTypedGroup<Actor>;
	public var notes:FlxTypedGroup<Note>;

	public var lastTexture:String = 'NOTE_assets';

	public var startX:Float = 0;
	public var startY:Float = 0;
	public var autoPlay:Bool = true;

	public var unspawnNotes:Array<Note> = [];
	public var speed:Float = 1;

	public var noteSplashes:FlxTypedGroup<NoteSplash>;

	public var characters:Array<Character> = [];

	public var hitSignal:FlxTypedSignal<Note->Void>;
	public var missSignal:FlxTypedSignal<Int->Void>;

	public function new(sX:Float = 0, sY:Float = 0)
	{
		super();
		startX = sX;
		startY = sY;

		hitSignal = new FlxTypedSignal<Note->Void>();
		missSignal = new FlxTypedSignal<Int->Void>();

		actors = new FlxTypedGroup<Actor>();
		add(actors);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		noteSplashes = new FlxTypedGroup<NoteSplash>();
		add(noteSplashes);

		regenerateActors();

		Conductor.onBeat.add(beatHit);
	}

	public function spawnSplashOnStrum(s:Actor)
	{
		var s2 = noteSplashes.recycle(NoteSplash);
		s2.setupNoteSplash(s);
		s2.revive();
	}

	public function regenerateActors()
	{
		while (actors.length > 0)
		{
			var actor = actors.members[0];
			actor.destroy();
			actors.remove(actor, true);
		}
		for (i in 0...4)
			addActor(i, 4);
	}

	public inline function addActor(i:Int, keys:Int = 4)
	{
		var startX = startX + (-Actor.Width * keys / 2);
		var actor:Actor = new Actor(i, lastTexture);
		actor.x = startX + (Actor.Width * i);
		actor.y = startY;
		actors.add(actor);
	}

	public function makeNote(time:Float, data:Int, length:Float, type:String)
	{
		var actor:Actor = actors.members[data];
		var note:Note = new Note(time, data, false, false, actor.lastTexture);
		note.actorline = this;
		note.prevNote = unspawnNotes[unspawnNotes.length - 1];
		unspawnNotes.push(note);

		return note;
	}

	public function makeHoldNote(time:Float, data:Int, steplength:Float, type:String, isTail:Bool)
	{
		var actor:Actor = actors.members[data];
		var note:Note = new Note(time, data, true, isTail, actor.lastTexture);
		note.actorline = this;
		note.seglength = steplength;
		note.prevNote = unspawnNotes[unspawnNotes.length - 1];
		unspawnNotes.push(note);
		return note;
	}

	public function sortPremade()
	{
		unspawnNotes.sort((n1:Note, n2:Note) ->
		{
			return Math.floor(n1.time - n2.time);
		});
	}

	public function updateNote(note:Note)
	{
		if (note.isTrail)
			note.updateSusLength(speed);

		var actor:Actor = actors.members[note.lane];
		note.setPosition(actor.x + actor.width * .5 - note.width * .5 + note.offsetX, actor.y + note.getDistance(actor, speed));

		if (autoPlay && note.hit && !note.hitByenemy)
		{
			note.hitByenemy = true;
			hitNote(note);
		}

		if (note.isTrail)
			note.clipToStrumNote(actor);

		if (note.time <= Conductor.time - (350 / speed))
		{
			if (!autoPlay && !note.hit)
			{
				miss(note.lane);
			}
			killNote(note);
		}
	}

	public function hitNote(note:Note)
	{
		var actor:Actor = actors.members[note.lane];
		actor.playAnim('confirm');
		note.hit = true;

		if (note.character != null)
		{
			note.character.hitNote(note);
		}
		else
		{
			for (char in characters)
			{
				char.hitNote(note);
			}
		}

		if (autoPlay)
		{
			actor.resetAnim = .15;
		}
		hitSignal.dispatch(note);
		if (!note.isTrail)
			killNote(note);
	}

	public function killNote(n:Note)
	{
		notes.remove(n, true);
		n.destroy();
		n = null;
	}

	public function miss(dir:Int)
	{
		for (char in characters)
			char.missDir(dir);
		missSignal.dispatch(dir);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (unspawnNotes.length > 0)
		{
			var n = unspawnNotes[0];
			if (n.time <= Conductor.time + (1500 / speed))
			{
				notes.insert(0, n);
				unspawnNotes.remove(n);
			}
		}

		if (!autoPlay)
			inputSystemStuff();
		notes.forEachAlive(updateNote);
	}

	public function beatHit(_)
	{
		notes.sort(sortNotesByTimeHelper, FlxSort.DESCENDING);
	}

	inline public static function sortNotesByTimeHelper(Order:Int, Obj1:Note, Obj2:Note)
		return FlxSort.byValues(Order, Obj1.time, Obj2.time);

	static function recycleClipRect(sprite:FlxSprite, i:Int = 0, i2:Int = 0, f:Float = 0, f2:Float = 0)
	{
		var rect = sprite.clipRect ?? new FlxRect(i, i2, f, f2);
		rect.set(i, i2, f, f2);
		rect.round();
		return rect;
	}

	public var pressedShit = [-1];
	public var hitNotes:Array<Note> = [];

	public var hitNotesInt:Array<Int> = [];

	public inline function inputSystemStuff()
	{
		pressedShit.resize(0);
		hitNotes.resize(0);
		hitNotesInt.resize(0);

		final holding = [
			inputSystem.pressed('note_left'),
			inputSystem.pressed('note_down'),
			inputSystem.pressed('note_up'),
			inputSystem.pressed('note_right')
		];

		final released = [
			inputSystem.justReleased('note_left'),
			inputSystem.justReleased('note_down'),
			inputSystem.justReleased('note_up'),
			inputSystem.justReleased('note_right')
		];

		final pressed = [
			inputSystem.justPressed('note_left'),
			inputSystem.justPressed('note_down'),
			inputSystem.justPressed('note_up'),
			inputSystem.justPressed('note_right')
		];

		if (holding.contains(true))
		{
			var laneNotes:Array<Note> = [null, null, null, null];

			notes.forEachAlive((n:Note) ->
			{
				if (n.canBeHit && !autoPlay && !n.hit)
				{
					var lane = n.lane;

					if (laneNotes[lane] == null)
					{
						laneNotes[lane] = n;
					}
					else if (n.time < laneNotes[lane].time)
					{
						laneNotes[lane] = n;
					}
				}
			});

			for (note in laneNotes)
			{
				if (note == null)
					continue;

				hitNotes.push(note);
				pressedShit[note.lane] = note.lane;
			}

			if (hitNotes.length > 0)
			{
				for (note in hitNotes)
				{
					var lane = note.lane;
					var lanePressed = pressed[lane];
					var laneHolding = holding[lane];

					if (!note.isTrail && lanePressed)
					{
						hitNote(note);
					}
					else if (note.isTrail && laneHolding)
					{
						hitNote(note);
					}
				}
			}
		}

		for (i in 0...pressed.length)
		{
			var strum = actors.members[i % actors.length];
			var lanePressed = pressed[i];
			var laneHolding = holding[i];

			strum.holding = laneHolding;

			if (lanePressed && strum.animation.name != 'confirm')
				strum.playAnim('press');
			else if (!laneHolding)
				strum.playAnim('grey');

			if (hitNotes.length > 0 && !pressedShit.contains(strum.lane) && lanePressed)
				miss(strum.lane);
		}
	}
}
