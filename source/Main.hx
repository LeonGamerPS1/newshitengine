package;

import debug.FunkinDebugDisplay;
import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;

class Main extends Sprite
{
	/**
	 * The debug display at the top left.
	 */
	public static var debugDisplay:FunkinDebugDisplay;

	public function new()
	{
		@:privateAccess
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, InitState.onCrash);

		super();

		addChild(new FlxGame(0, 0, InitState, 60, 60, true));

		debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);
		addChild(debugDisplay);

		FlxG.signals.preUpdate.add(function(){
			if(FlxG.keys.justPressed.F5)
				FlxG.resetState();
		});
	}

	#if (!debug)
	// Get rid of hit test function because mouse memory ramp up during first move (-Bolo)
	@:noCompletion override function __hitTest(_, _, _, _, _, _):Bool
		return false;

	@:noCompletion override function __hitTestHitArea(_, _, _, _, _, _):Bool
		return false;

	@:noCompletion override function __hitTestMask(_, _):Bool
		return false;
	#end
}
