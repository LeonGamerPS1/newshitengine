package objects.gameplay;

typedef StageFile =
{
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

/**
 * Stage shi
 */
class BaseStage extends FlxBasic
{
	public function new(stageName:String = 'empty')
	{
		super();
	}

	/**
	 * Stuff under characters (characters are not available at this stage so be careful)
	 */
	public function onCreate() {}

	/**
	 * For stuff above characters
	 */
	public function onCreatePost() {}

	public function onStepHit(step:Int) {}

	public function onBeatHit(beat:Int) {}

	public function onSectionHit(section:Int) {}

	function add(object:FlxBasic)
		FlxG.state.add(object);

	function remove(object:FlxBasic)
		FlxG.state.remove(object);

	function insert(position:Int, object:FlxBasic)
		FlxG.state.insert(position, object);
}
