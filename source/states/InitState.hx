package states;

import backend.Song;
import backend.input.Controls;
import debug.FunkinDebugDisplay;
import debug.MemoryUtil;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.input.keyboard.FlxKey;
import flixel.system.scaleModes.BaseScaleMode;
import flixel.system.scaleModes.BaseScaleMode;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import lime.utils.Assets;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import sys.FileSystem;
import sys.io.File;

#if linux @:cppInclude('../../../vendor/linux/include/gamemode_client.h') #end
class InitState extends FunkinState
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

	public override function create()
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
		cplusplus.windows.CPPWinBackend.setDPIAware();
		cplusplus.windows.CPPWinBackend.setWindowDarkMode(lime.app.Application.current.window.title, true);
		#end

		FlxG.cameras.bgColor = 0x00000000;
		FlxG.cameras.useBufferLocking = true;
		FlxG.fixedTimestep = false;

		#if hxcpp_debug_server
		trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
		#else
		trace('hxcpp_debug_server is disabled! This build does not support debugging.');
		#end

		FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode(true);
		FlxG.signals.gameResized.add(onGameResized);

		FlxG.scaleMode = new AspectRatioFillScale();
		FlxG.signals.preStateSwitch.add(Conductor.reset);

		Controls.init();

		modding.Mods.init();
		trace('loaded ' + modding.Mods.mods.length + ' mods');
		@:privateAccess FlxG.keys._nativeCorrection.set("0_43", FlxKey.PLUS);

		final args = Sys.args();

		var hasSong = false;
		for (arg in args)
		{
			if (StringTools.startsWith(arg, 'song='))
			{
				hasSong = true;
				break;
			}
		}

		if (hasSong)
		{
			
			var diff = getDefinedValue(args, 'diff', 'hard');
			var song = getDefinedValue(args, 'song', 'careless');

			PlayState.song = Song.loadFromJson(diff, song);
			FlxG.switchState(new PlayState());
			return;
		}
		Main.switchState(new MainMenu());
	}

	static function getDefinedValue(args:Array<String>, name:String, defau:String):String
	{
		var prefix = name + "=";
		for (arg in args)
		{
			if (arg.indexOf(prefix) == 0)
			{
				return arg.substring(prefix.length);
			}
		}
		return defau;
	}

	function onGameResized(width:Int, height:Int)
	{
		if (FlxG.cameras != null)
		{
			for (cam in FlxG.cameras.list)
			{
				if (cam != null && (cam.filters != null && cam.filters.length > 0))
					resetSpriteCache(cam.flashSprite);
			}
		}

		if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
	}

	inline function resetSpriteCache(sprite:Sprite)
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
			sprite.__cacheBitmapData2 = null;
			sprite.__cacheBitmapData3 = null;
			sprite.__cacheBitmapColorTransform = null;
		}
	}

	static function onCrash(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopImmediatePropagation();

		var errMsg:String = '${e.error}\n\n';
		var date:String = '${Date.now()}'.replace(":", "'");

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case FilePos(_, file, line, _):
					errMsg += 'Called from $file:$line\n';
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += '\nExtra Info:\n';
		errMsg += 'Operating System: ${Util.getOperatingSystem()}\nTarget: ${Util.getTarget()}\n\n';

		final defines:Map<String, Dynamic> = macr.Cdef.list;
		errMsg += 'Haxe: ${defines['haxe']}\nFlixel: ${defines['flixel']}\nOpenFL: ${defines['openfl']}\nLime: ${defines['lime']}';

		if (!FileSystem.exists('./crash/'))
			FileSystem.createDirectory('./crash/');

		File.saveContent('./crash/$date.txt', '$errMsg\n');
		Sys.println('\n$errMsg');
		lime.app.Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}
}

class AspectRatioFillScale extends BaseScaleMode
{
	override function onMeasure(windowWidth:Int, windowHeight:Int):Void
	{
		// 1. Berechne die Skalierungsfaktoren für beide Achsen
		var scaleX:Float = windowWidth / FlxG.width;
		var scaleY:Float = windowHeight / FlxG.height;

		// 2. Nutze den KLEINEREN Faktor, um Verzerrung zu verhindern
		var finalScale:Float = (scaleX < scaleY) ? scaleX : scaleY;

		// 3. Setze die Spielgröße exakt auf die Fenstergröße (beseitigt die Balken)
		gameSize.set(windowWidth, windowHeight);

		// 4. Skaliere das Spiel ohne Verzerrung
		scale.set(finalScale, finalScale);

		// 5. Keine Offsets – das Spiel nutzt den vollen Canvas
		offset.set(0, 0);

		// 6. Passe die Kamera-Größe an, damit sie Breite und Höhe komplett ausfüllt
		if (FlxG.camera != null)
		{
			FlxG.camera.width = Math.ceil(windowWidth / finalScale);
			FlxG.camera.height = Math.ceil(windowHeight / finalScale);
		}
	}
}
