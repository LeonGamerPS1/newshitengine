package objects;

class ActorLine extends FlxGroup
{
	public var actors:FlxTypedGroup<Actor>;
	public var lastTexture:String = 'NOTE_assets';

	public var startX:Float = 0;
	public var startY:Float = 0;

	public function new(sX:Float = 0, sY:Float = 0)
	{
		super();
        startX = sX;
        startY = sY;
		actors = new FlxTypedGroup<Actor>();
		add(actors);

		regenerateActors();
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

	inline function addActor(i:Int, keys:Int = 4)
	{
		var startX = startX + (-Actor.Width * keys / 2);
		var actor:Actor = new Actor(i, lastTexture);
		actor.x = startX + (Actor.Width * i);
        actor.y = startY;
        actors.add(actor);
	}
}
