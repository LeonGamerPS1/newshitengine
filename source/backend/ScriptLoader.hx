package backend;

import haxe.io.Path;
import modding.scripts.BaseScript;
#if !html5
import modding.scripts.Hscript;
#end

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
			#if !html5
			case 'hx' | 'hscript' | 'hxc' | 'hxs':
				return new Hscript(path);
			#end
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
