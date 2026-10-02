package;

import flixel.FlxGame;
import lime.app.Application;
import openfl.display.Sprite;

#if linux @:cppInclude('../../../vendor/linux/include/gamemode_client.h') #end
class Main extends Sprite
{
	public function new()
	{
		// gamemode client.h
		#if linux
		var errcode = 0;
		untyped untyped __cpp__('errcode = gamemode_request_start()');
		trace(errcode == 0 ? 'succesfully started gamemode' : 'failed to start gamemode_client.h');
		Application.current.onExit.add((excode:Int) ->
		{
			var errcode = 0;
			untyped untyped __cpp__('errcode = gamemode_request_end()');
			trace(errcode == 0 ? 'succesfully ended gamemode' : 'failed to end gamemode_client.h');
		}, true, 1);
		#end

		super();
		FlxG.cameras.bgColor = 0x0;
		FlxG.cameras.useBufferLocking = true;

		
		addChild(new FlxGame(0, 0, PlayState, 60, 60));
		addChild(new openfl.display.FPS(10, 10, 0xFFFFFFFF));
	}
}
