package modding.scripts;

class BaseScript
{
	public var path:String;
	public var name:String;
	public var dummy:Bool = true;

	public function new(path:String)
	{
		this.path = path;
		this.name = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(path));

		load(path);
	}

	function load(path:String) {}

	public function getVariable(name:String):Dynamic
	{
		return null;
	}

	public function setVariable(name:String, va:Dynamic) {}

	public function call(fn:String, ?args:Array<Dynamic>):Dynamic
	{
		var fn = getVariable(fn);
		if (fn != null)
			return Reflect.callMethod(null, fn, args);
		return null;
	}

	public function setDefaultVars()
	{
		setVariable('curBeat', 1);
		setVariable('curStep', 1);
		setVariable('curSection', 1);
		setVariable('downscroll', false);
		setVariable('os',
			#if windows 'windows' #else #if linux 'linux' #else #if mac 'mac' #else #if android 'android' #else #if ios 'ios' #else 'unknown' #end #end #end #end #end);
		setVariable('middlescroll', false);

		setVariable('getActorX', function(lane:Int = 0, line:Int = 0)
		{
			if (PlayState.instance != null)
				return PlayState.instance.actorLines[line].actors.members[lane].x;
			return 0;
		});

		setVariable('getActorY', function(lane:Int = 0, line:Int = 0)
		{
			if (PlayState.instance != null)
				return PlayState.instance.actorLines[line].actors.members[lane].x;
			return 0;
		});

		setVariable('setActorX', function(x:Float = 0, lane:Int = 0, line:Int = 0)
		{
			if (PlayState.instance != null)
				PlayState.instance.actorLines[line].actors.members[lane].x = x;
		});

		setVariable('setActorY', function(y:Float = 0, lane:Int = 0, line:Int = 0)
		{
			if (PlayState.instance != null)
				PlayState.instance.actorLines[line].actors.members[lane].y = y;
		});

		setVariable('tweenPos', function(x:Float = 0, y:Int = 0, obj:FlxObject,dur:Float = 1,?poop:Bool)
		{
			FlxTween.tween(obj,{x:x,y:y},dur);
		});

		setVariable("setVar", function(varname:String, value:Dynamic)
		{
			if (PlayState.instance != null)
				PlayState.instance.variables[varname] = value;
		});

		setVariable("getVar", function(varname:String)
		{
			if (PlayState.instance != null)
				return PlayState.instance.variables[varname];
			return null;
		});
	}
}
