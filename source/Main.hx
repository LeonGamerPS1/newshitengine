package;

import debug.FunkinDebugDisplay;
import flixel.FlxGame;
import objects.effects.CustomFadeTransition;
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

		addChild(new FlxGame(0, 0, InitState, 64, 64, true));

		debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);
		addChild(debugDisplay);

		FlxG.signals.preUpdate.add(function()
		{
			if (FlxG.keys.justPressed.F5)
				resetState();
		});

		FlxG.game.focusLostFramerate = 2000;
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

	public static function switchState(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;
		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState()
	{
		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function startTransition(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}
}
