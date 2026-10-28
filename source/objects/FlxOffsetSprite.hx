package objects;

class FlxOffsetSprite extends FlxSprite
{
	/**
	 * The position of the sprite's render offset relative to its original  position/xy. For example, `offset.x = 10;` will
	 * show the sprite 10 pixels right of the actual position that it normally would be at. This is mainly used in the modcharting system for notes and stuff.
	 */
	public var renderOffset(default, null):FlxPoint;

	@:noCompletion
	override function initVars():Void
	{
		super.initVars();

		renderOffset = FlxPoint.get();
	}

	override public function destroy():Void
	{
		super.destroy();

		renderOffset = FlxDestroyUtil.put(renderOffset);
	}

	public override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
	{
		return super.getScreenPosition(result, camera).add(renderOffset);
	}
}
