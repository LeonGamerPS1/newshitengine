package modding;

import lime.app.Application;
import sys.FileSystem;
import sys.io.File;

typedef ModJson =
{
	var name:String;
	var id:String;
    var global:Bool;

	@:optional
	var enabled:Bool;
}

class Mods
{
	public static var mods:Array<ModJson> = [];
	public static var MOD_ROOT:String = './mods';

	public static function init()
	{
		FlxG.save.data.modDatas ??= {};
		trace(FlxG.save.data.modDatas);
		Application.current.onExit.add((a) ->
		{
			for (mod in mods)
			{
				Reflect.setField(FlxG.save.data.modDatas, mod.id, {enabled: mod.enabled, id: mod.id});
			}
		});

		if (!FileSystem.exists(MOD_ROOT))
			FileSystem.createDirectory(MOD_ROOT);
		else if (!FileSystem.isDirectory(MOD_ROOT))
		{
			trace('deleting file $MOD_ROOT, creating new folder in place');
			FileSystem.deleteFile(MOD_ROOT);
			FileSystem.createDirectory(MOD_ROOT);
		}

		var folders = FileSystem.readDirectory(MOD_ROOT);
		for (folder in folders)
		{
			if (!FileSystem.isDirectory(MOD_ROOT + '/' + folder))
				continue;
			var data:Dynamic;
			var meta:ModJson = haxe.Json.parse(Paths.getText(MOD_ROOT + '/' + folder + '/pack.json'));
			if (!Reflect.hasField(FlxG.save.data.modDatas, folder))
			{
				data = {id: folder, enabled: false};
			}
			else
				data = Reflect.getProperty(FlxG.save.data.modDatas, folder);
            meta.id = folder;
			meta.enabled = data.enabled;
			mods.push(meta);
		}
	}

	public static function enableMod(modid:String)
	{
		for (mod in mods)
		{
			if (mod.id == modid && !mod.enabled)
			{
				mod.enabled = true;
				break;
			}
		}
	}

	public static function disableMod(modid:String)
	{
		for (mod in mods)
		{
			if (mod.id == modid && mod.enabled)
			{
				mod.enabled = false;
				break;
			}
		}
	}

	public static function getActiveMods():Array<ModJson>
	{
        var ar:Array<ModJson> = [];
		for (mod in mods)
		{
			if (mod.enabled || mod.global)
			{
				ar.push(mod);
			}
		}
        return ar;
	}
}
