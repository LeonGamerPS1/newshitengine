package states;

import objects.effects.CustomFadeTransition;

class FunkinState extends FlxState
{
	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		super.create();

		openSubState(new CustomFadeTransition(0.5, true));

		FlxTransitionableState.skipNextTransOut = false;
	}
}
