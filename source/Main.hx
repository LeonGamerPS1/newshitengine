package;

import backend.input.Controls;
import debug.FPS_Mem;
import flixel.FlxGame;
import haxe.io.Path;
import hxscript.compile.Compiler;
import lime.app.Application;
import openfl.display.Sprite;

#if linux @:cppInclude('../../../vendor/linux/include/gamemode_client.h') #end
class Main extends Sprite
{
	#if desktop
	// stolen from psych engine lol
	static function __init__()
	{
		var configPath:String = Path.directory(Path.withoutExtension(#if hl Sys.getCwd() #else Sys.programPath() #end));

		#if windows
		configPath += "/alsoft.ini";
		#elseif mac
		configPath = Path.directory(configPath) + "/Resources/alsoft.conf";
		#elseif linux
		configPath += "/alsoft.conf";
		#end

		Sys.putEnv("ALSOFT_CONF", configPath);
	}
	#end

	public function new()
	{
		// gamemode client.h
		#if linux
		var errcode = 0;
		untyped __cpp__('errcode = gamemode_request_start()');
		trace(errcode == 0 ? 'succesfully started gamemode' : 'failed to start gamemode_client.h');
		Application.current.onExit.add((excode:Int) ->
		{
			var errcode = 0;
			untyped __cpp__('errcode = gamemode_request_end()');
			trace(errcode == 0 ? 'succesfully ended gamemode' : 'failed to end gamemode_client.h');
		}, true, 1);
		#end

		super();
		FlxG.cameras.bgColor = 0x00000000;
		FlxG.cameras.useBufferLocking = true;
		FlxG.fixedTimestep = false;

		Controls.init();

		addChild(new FlxGame(0, 0, PlayState, 60, 60));
		var fps:FPS_Mem = new FPS_Mem(10, 10, 0xffffff);
		addChild(fps);

		trace(Compiler.unavailable());
	}
}
