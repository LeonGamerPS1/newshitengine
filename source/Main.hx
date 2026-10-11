package;

import backend.input.Controls;
import debug.DebugTracker;
import debug.MemoryUtil;
import flixel.FlxGame;
import flixel.graphics.tile.FlxDrawBaseItem;
import haxe.io.Path;
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

		#if (windows && cpp)
			cplusplus.windows.CPPWinBackend.makeDpiAware();
		#end

		super();
		FlxG.cameras.bgColor = 0x00000000;
		FlxG.cameras.useBufferLocking = true;
		FlxG.fixedTimestep = false;

		Controls.init();

		addChild(new FlxGame(0, 0, PlayState, 60, 60));
		// Diese Variablen müssen außerhalb der Schleife/Funktion definiert werden (z. B. in deiner Klasse)
		var lastTime:Float = haxe.Timer.stamp();
		var frameCount:Int = 0;
		var currentFps:Int = 0;

		// Die korrekte Zuweisung für deinen DebugTracker
		var fps:DebugTracker = new DebugTracker(10, 10, 0xffffff);
		fps.addSection('General', [
			{
				displayName: "FPS",
				valueFunc: () ->
				{
					frameCount++;
					var now = haxe.Timer.stamp();
					if (now - lastTime >= 1.0)
					{
						currentFps = frameCount;
						frameCount = 0;
						lastTime = now;
					}
					return currentFps;
				},
			},
			{
				displayName: "RAM",
				valueFunc: () ->
				{
					return FlxStringUtil.formatBytes(MemoryUtil.getMemory());
				}
			},

		]);

		fps.addSection('Flixel/Game', [
			{
				displayName: "Draw Calls:",
				valueFunc: () ->
				{
					return FlxDrawBaseItem.drawCalls;
				}
			},

			{
				displayName: "Bitmaps Cached",
				valueFunc: () ->
				{
					@:privateAccess
					return Lambda.count(FlxG.bitmap._cache);
				}
			},
			{
				displayName: "Sounds active/Playing",
				valueFunc: () ->
				{
					return FlxG.sound.list.length;
				}
			},

			{
				displayName: "Bitmaps Cached (Paths)",
				valueFunc: () ->
				{
					return Lambda.count(Paths.cachedImages);
				}
			},
			{
				displayName: "Sounds Cached (Paths)",
				valueFunc: () ->
				{
					return Lambda.count(Paths.cachedSounds);
				}
			},

		]);

		fps.addSection('Conductor', [

			{
				displayName: "Song Position (sec)",
				valueFunc: () ->
				{
					return Conductor.time / 1000;
				},
			},

			{
				displayName: "Current BPM",
				valueFunc: () ->
				{
					return Conductor.bpm;
				}
			},
			{
				displayName: "Current Step",
				valueFunc: () ->
				{
					return Conductor.curStep;
				}
			},
			{
				displayName: "Current Beat",
				valueFunc: () ->
				{
					return Conductor.curBeat;
				}
			},
			{
				displayName: "Current Section",
				valueFunc: () ->
				{
					return Conductor.curSection;
				}
			}

		]);

		addChild(fps);
	}
}
