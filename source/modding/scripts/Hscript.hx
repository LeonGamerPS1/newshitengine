package modding.scripts;

import hxscript.Script;

class Hscript extends BaseScript
{
	var script:Script;

	override function load(path:String)
	{
		var input = Paths.getText(path);
		script = new Script(input, path);

		setDefaultVars();
		script.interp.parent = FlxG.state;


		script.start();
		setVariable('FlxG', flixel.FlxG);
		setVariable('FlxMath', flixel.math.FlxMath);
		setVariable('FlxSprite', flixel.FlxSprite);
		setVariable('FlxText', flixel.text.FlxText);
		setVariable('FlxCamera', flixel.FlxCamera);
		setVariable('FlxTimer', flixel.util.FlxTimer);
		setVariable('FlxTween', flixel.tweens.FlxTween);
		setVariable('FlxEase', flixel.tweens.FlxEase);
		setVariable('PlayState', PlayState);
		setVariable('Paths', Paths);
		setVariable('Conductor', Conductor);
		setVariable('game', FlxG.state);


		call('new');
	}

	override public function getVariable(name:String):Dynamic
	{
		return script.variables.get(name);
	}

	override public function setVariable(name:String, va:Dynamic)
	{
		script.variables.set(name, va);
	}

	override public function call(fn:String, ?args:Array<Dynamic>):Dynamic
	{
		var fun = (script.variables.get(fn) ?? script.interp.getLocal(fn));
		if(fun == null)
			return null;
		return script.call(fn, args ?? []);
	}
}
