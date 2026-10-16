package;

import backend.input.Controls;
import debug.FunkinDebugDisplay;
import debug.MemoryUtil;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.system.scaleModes.BaseScaleMode;
import flixel.system.scaleModes.BaseScaleMode;
import haxe.io.Path;
import lime.app.Application;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
#if linux @:cppInclude('../../../vendor/linux/include/gamemode_client.h') #end
class Main extends Sprite
{
	/**
	 * The debug display at the top left.
	 */
	public static var debugDisplay:FunkinDebugDisplay;

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
		cplusplus.windows.CPPWinBackend.setDPIAware();
		cplusplus.windows.CPPWinBackend.setWindowDarkMode(lime.app.Application.current.window.title, true);
		#end

		super();
		FlxG.cameras.bgColor = 0x00000000;
		FlxG.cameras.useBufferLocking = true;
		FlxG.fixedTimestep = false;

		Controls.init();

		addChild(new FlxGame(0, 0, PlayState, 64,64));

		getChildAt(0).name = 'FlxGame';

		debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);
		debugDisplay.name = 'FPSCounter';
		addChild(debugDisplay);

		#if hxcpp_debug_server
		trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
		#else
		trace('hxcpp_debug_server is disabled! This build does not support debugging.');
		#end

		FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode(true);
		FlxG.signals.gameResized.add(onGameResized);

		FlxG.scaleMode = new AspectRatioFillScale();
		FlxG.signals.preStateSwitch.add(Conductor.reset);
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
        if (FlxG.camera != null) {
            FlxG.camera.width = Math.ceil(windowWidth / finalScale);
            FlxG.camera.height = Math.ceil(windowHeight / finalScale);
        }
    }
}
