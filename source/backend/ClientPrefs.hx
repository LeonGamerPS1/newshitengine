package backend;

import lime.app.Application;

@:structInit
class SaveData
{
	// Gameplay
	public var downscroll:Bool = false;
	public var middlescroll:Bool = false;
	public var offset:Float = 0;

	// Performance stuff
	public var antialiasing:Bool = true;
	public var cacheOnGPU:Bool = true;
	public var refreshRate:Int = 64;
}

class ClientPrefs
{
	public static var defaultData:SaveData = {};
	public static var data:SaveData;

	private static var _save:FlxSave;

	public static function init()
	{
		data = {};
		_save = new FlxSave();
		_save.bind('settings', 'FunkinShit');

		Application.current.window.onClose.add(() ->
		{
			for (field in Reflect.fields(data))
				Reflect.setProperty(_save.data, field, Reflect.getProperty(data, field));
			_save.flush();
			_save.destroy();
			_save = null;
		}, true, 1);

		for (field in Reflect.fields(data))
		{
			if (Reflect.hasField(_save.data, field))
				Reflect.setField(data, field, Reflect.getProperty(_save.data, field));
		}
	}

	public static function setVal(name:String, val:Dynamic)
	{
		if (name == null)
			return;
		try
		{
			Reflect.setProperty(data, name, val);
		}
		catch (e:Dynamic)
		{
			Application.current.window.alert(Std.string(e), 'Error');
		}
		FlxG.save.flush();

		FlxG.drawFramerate = FlxG.updateFramerate = data.refreshRate;
	}
}
