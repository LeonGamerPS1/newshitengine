package modchart;

import objects.Actor;
import objects.Note;
import openfl.geom.ColorTransform;

enum ModifierType
{
	NOTES;
	STRUM;
}

typedef VisualParams =
{
	var x:Float;
	var y:Float;
	var angle:Float;
	var scaleX:Float;
	var scaleY:Float;
	var alpha:Float;
	var color:ColorTransform;
}

typedef VisualParamOutput = VisualParams;

class Modifier
{
	public var name:String;
	public var player:Int = 0;
	public var modmanager:ModchartSystem;

	public function new(mm:ModchartSystem)
	{
		modmanager = mm;
	}

	/** Current percent of this modifier for the player it belongs to. */
	public function getPercent():Float
	{
		return modmanager.getPercent(name, player);
	}

	public function processVisuals(visualParams:VisualParams, isNote:Bool = false, objNote:Note, objStrum:Actor) {}

	/** By default a modifier only runs while its percent is not 0. */
	public function shouldRun():Bool
	{
		return getPercent() != 0;
	}

	public function update(elapses:Float) {}
}

/**
 * Shifts strums horizontally. 100% = one arrow width (ModchartSystem.ARROW_SIZE).
 */
class MoveX extends Modifier
{
	override public function processVisuals(visualParams:VisualParams, isNote:Bool = false, objNote:Note, objStrum:Actor)
	{
		visualParams.x += getPercent() * 0.01 * ModchartSystem.ARROW_SIZE;
	}
}

/**
 * Shifts strums vertically. 100% = one arrow width (ModchartSystem.ARROW_SIZE).
 */
class MoveY extends Modifier
{
	override public function processVisuals(visualParams:VisualParams, isNote:Bool = false, objNote:Note, objStrum:Actor)
	{
		visualParams.y += getPercent() * 0.01 * ModchartSystem.ARROW_SIZE;
	}
}

/**
 * Notes zigzag left and right as they travel toward the strum (notes only).
 * 100% = the zigzag swings one arrow width to each side.
 * The offset is exactly 0 when a note reaches its strum, so hits still line up.
 */
class ZigZag extends Modifier
{
	/** Distance in pixels a note travels for one full zigzag (out, back, across, back). */
	public static var WAVELENGTH:Float = 400;

	override public function processVisuals(visualParams:VisualParams, isNote:Bool = false, objNote:Note, objStrum:Actor)
	{
		if (!isNote || objNote == null || objStrum == null)
			return;

		// how far the note still is from its strum, in wavelengths (+0.25 so the wave is 0 at the strum)
		var t = (objNote.y - objStrum.y) / WAVELENGTH + 0.25;
		// triangle wave from -1 to 1
		var tri = Math.abs((t - Math.floor(t)) * 2 - 1) * 2 - 1;

		visualParams.x += tri * getPercent() * 0.01 * ModchartSystem.ARROW_SIZE;
	}
}

/**
 * Fades notes out (notes only, strums stay visible).
 * 0% = normal, 50% = half see-through, 100% = invisible.
 */
class Stealth extends Modifier
{
	override public function processVisuals(visualParams:VisualParams, isNote:Bool = false, objNote:Note, objStrum:Actor)
	{
		if (!isNote)
			return;

		var p = getPercent() * 0.01;
		if (p > 1)
			p = 1;
		else if (p < 0)
			p = 0;

		visualParams.alpha *= 1 - p;
	}
}
