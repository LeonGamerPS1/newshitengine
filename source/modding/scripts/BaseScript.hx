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

	public function setDefaultVars() {}
}
