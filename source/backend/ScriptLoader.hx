package backend;

import haxe.io.Path;
import modding.scripts.BaseScript;
import modding.scripts.Hscript;


class ScriptLoader
{
	public static function loadScript(path:String, NullNonexisting:Bool = false):BaseScript
	{
		var ext = Path.extension(path);
		if (!Paths.exists(path))
		{
			trace('script $path does not exist');
			return !NullNonexisting ? new BaseScript(path) : null;
		}
		switch (ext)
		{
			default:
				trace('script $ext unsupported');
				return new BaseScript(path);
			case 'hx' | 'hscript' | 'hxc' | 'hxs':
				return new Hscript(path);
		}
	}

	public static function loadScripts(paths:Array<String>):Array<BaseScript>
	{
		var scripts:Array<BaseScript> = [];
		for (i in paths)
			scripts.push(loadScript(i));

		return scripts;
	}
}
