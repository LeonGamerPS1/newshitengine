package backend;

import lime.app.Application;

@:structInit
class SaveData
{
	public var antialiasing:Bool = true;
	public var antialiasingQuality:String = 'Max';
	// GPU stuff
	public var cacheOnGPU:Bool = true;
	public var vortexPixel:Bool = true;
	public var vortexEnhance:Bool = true;
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

		for (field in Reflect.fields(_save.data))
		{
			if (Reflect.hasField(data, field))
				Reflect.setField(data, field, Reflect.getProperty(_save.data, field));
		}
	}
}
