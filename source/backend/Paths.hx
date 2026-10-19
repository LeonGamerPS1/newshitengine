package backend;

import animate.FlxAnimateFrames;
import animate.FlxAnimateFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMatrix;
import haxe.MainLoop;
import haxe.io.Path;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import modding.Mods;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import sys.FileSystem;
import sys.io.File;

class Paths
{
	public static var cachedImages:haxe.ds.StringMap<FlxGraphic> = new haxe.ds.StringMap<FlxGraphic>();
	public static var cachedSounds:haxe.ds.StringMap<Sound> = new haxe.ds.StringMap<Sound>();
	public static var cachedAtlases:haxe.ds.StringMap<FlxFramesCollection> = new haxe.ds.StringMap<FlxFramesCollection>();

	public static function clearGraphics()
	{
		for (k => img in cachedImages)
		{
			if (img == null || img.destroyOnNoUse)
				continue;

			OpenFLAssets.cache.clear(k);
			img.persist = false;
			@:bypassAccessor
			img.destroyOnNoUse = true;
			img.destroy();
			img = null;
		}
		cachedImages.clear();
		for (atlas in cachedAtlases)
			atlas.destroy();
		cachedAtlases.clear();

		FlxG.bitmap.clearCache();
		OpenFLAssets.cache.clear('assets/images');
	}

	public static function getPath(path:String)
	{
		if (path.startsWith('assets'))
			path = path.replace('assets/', '');
		for (mod in Mods.getActiveMods())
		{
			var path = Path.join([Mods.MOD_ROOT, mod.id, path]);

			if (FileSystem.exists(path))
				return path;
		}
		return 'assets/$path';
	}

	static public var defaultMatrix:FlxMatrix = new FlxMatrix();

	public static function getGraphic(path:String):FlxGraphic
	{
		path = getPath('images/$path.png');
		if (cachedImages.exists(path))
			return cachedImages.get(path);

		if (!FileSystem.exists(path))
		{
			FlxG.log.warn('oh noes! image not here $path');
			return null;
		}

		var bitmap = BitmapData.fromFile(path);

		bitmap.disposeImage();

		var graphic = FlxGraphic.fromBitmapData(bitmap, false, path, false);
		graphic.persist = true;
		cachedImages.set(path, graphic);
		return graphic;
	}

	public static function clear()
	{
		if (FlxG.state is PlayState)
			return;
		clearGraphics();
	}

	public static var defaultListExludes = ['assets/data/scripts/stages'];

	public static function listDirectory(startPath:String, type:AssetType = null, ?excludes:Array<String>):Array<String>
	{
		excludes ??= defaultListExludes;
		var dir = OpenFLAssets.list(type).filter((e) ->
		{
			return e.startsWith(startPath) && !excludes.contains(startPath);
		});

		return dir;
	}

	public static function getSound(path:String, stream:Bool = false, soundType:SoundExtension = #if flash MP3 #else OGG #end):Sound
	{
		path = getPath('$path.$soundType');
		#if !sys stream = false; #end
		if (cachedSounds.exists(path))
			return cachedSounds.get(path);

		if (!FileSystem.exists(path))
			return null;

		var sound:Sound = stream ? streamed(path) : Sound.fromFile(path);
		cachedSounds.set(path, sound);
		return sound;
	}

	public static function exists(s:String, ?type:AssetType)
	{
		if (FileSystem.exists(s))
			return true;
		var path = getPath(s);
		return FileSystem.exists(path);
	}

	public static function getFont(path:String, fontType:FontExtension = TTF):String
	{
		path = getPath('fonts/$path.$fontType');

		return path;
	}

	//* for example, notes/poo, xml and png get added on their own
	public static function getSparrowAtlas(path:String):FlxAtlasFrames
	{
		var pathXML = getPath('images/$path.xml');
		var pathPng = getPath('images/$path.png');

		if (cachedAtlases.exists(pathXML))
			return cast cachedAtlases.get(pathXML);
		else if (cachedAtlases.exists(pathPng))
			return cast cachedAtlases.get(pathXML);
		if (!FileSystem.exists(pathPng) || !FileSystem.exists(pathXML))
		{
			FlxG.log.warn('oh noes!!! atlas not here!!! $pathPng | $pathXML');
			return null;
		}

		var atlas = FlxAtlasFrames.fromSparrow(getGraphic(path), getText(pathXML));
		atlas.parent.persist = true;
		cachedAtlases.set(pathXML, atlas);
		cachedAtlases.set(pathPng, atlas);
		return atlas;
	}

	public static function getMultiSparrowAtlas(paths:Array<String>):FlxAtlasFrames
	{
		if (paths.length == 1)
			return getSparrowAtlas(paths[0]);
		if (cachedAtlases.exists(paths.toString()))
			return cast cachedAtlases.get(paths.toString());

		var megaAtlas = new FlxAtlasFrames(null);
		for (goreSee in paths)
		{
			var atlas = getSparrowAtlas(goreSee);
			if (atlas != null)
				megaAtlas.addAtlas(atlas);
		}
		cachedAtlases.set(paths.toString(), megaAtlas);

		return megaAtlas;
	}

	public static function getAnimateAtlas(path:String):FlxAnimateFrames
	{
		var path = getPath('images/$path');
		final animJSON = path + "/Animation.json";

		if (cachedAtlases.exists(animJSON))
			return cast cachedAtlases.get(animJSON);
		if (!FileSystem.exists(animJSON))
		{
			FlxG.log.warn('oh noes!!! atlas not here!!! $path');
			return null;
		}

		var atlas = FlxAnimateFrames.fromAnimate(path);
		atlas.parent?.bitmap.disposeImage();
		cachedAtlases.set(animJSON, atlas);
		atlas.parent.persist = true;

		return atlas;
	}

	/**
	 * @author TheRealJake12, slightly edited by LeonGamerPS1
	 * Wack Ass Attempt To Make An OpenFl Equivalent For `FileSystem.readDirectory`
	 * @param path Directory To Scan. Doesn't Need the `assets/` prefix.
	 * @param type Type Of Files To List. "" Gets All Files While "TEXT" Will Only Retrieve Text Files (duh)
	 * @param suffix The Suffix Of The Files To Find. .lua Would Only Return Lua Files.
	 * @param removePath To Keep The `assets/path` Prefix When Returned. If True, It'll Just Be The Name Of The File With The Extension.
	 * @return Array<String>
	 */
	public static function readAssetsDirectoryFromLibrary(path:String, ?type:String, ?suffix:String = "", ?removePath:Bool = false,
			?library:String = "default"):Array<String>
	{
		final lib = OpenFLAssets.getLibrary(library ?? 'default');
		final list:Array<String> = lib.list(type);
		path = 'assets/$path';
		var stringList:Array<String> = [];
		for (mod in Mods.getActiveMods())
		{
			var basePath = Mods.MOD_ROOT + '/' + mod.id + '/' + path.replace('assets/', '');
			trace('scanning in mods for path $basePath');
			if (!FileSystem.exists(basePath))
				continue;

			for (file in FileSystem.readDirectory(basePath))
			{
				var pathToAdd = removePath ? file : '$basePath/$file';
				trace(pathToAdd);
				if (!pathToAdd.endsWith(suffix))
					continue;
				stringList.push(pathToAdd);
			}
		}
		for (hmm in list)
		{
			if (!hmm.startsWith(path) || !hmm.endsWith(suffix))
				continue;
			var bruh:String = null;
			if (removePath)
				bruh = hmm.replace('$path/', '');
			else
				bruh = hmm;
			stringList.push(bruh);
		}
		stringList.sort(Reflect.compare);
		return stringList;
	}

	public static function fragShader(shaderName:String)
	{
		var path = getPath('shaders/$shaderName.frag');
		return path;
	}

	public static function streamed(id:String, useCache:Bool = true):Sound
	{
		#if (lime_vorbis && lime > "7.9.0")
		var path = id;
		var vorbisFile = VorbisFile.fromFile(path);
		if (vorbisFile != null)
		{
			var buffer = AudioBuffer.fromVorbisFile(vorbisFile);
			return Sound.fromAudioBuffer(buffer);
		}
		else
		{
			// TODO: Streaming sound
			return Sound.fromFile(id);
		}
		#else
		// TODO: Streaming sound
		return Sound.fromFile(id);
		#end
	}

	public static function vertShader(shaderName:String)
	{
		var path = getPath('shaders/$shaderName.vert');
		return path;
	}

	public static function GetVertShader(shaderName:String):String
	{
		var path = vertShader(shaderName);
		return getText(path);
	}

	public static function GetFragShader(shaderName:String):String
	{
		var path = fragShader(shaderName);
		return getText(path);
	}

	public static function getText(path:String)
	{
		if (FileSystem.exists(path))
			return File.getContent(path);
		return File.getContent(getPath(path));
	}
}

enum abstract SoundExtension(String)
{
	var WAV = "wav";
	var OGG = "ogg";
	var MP3 = "mp3";
}

enum abstract FontExtension(String)
{
	var TTF = "ttf";
	var OTF = "otf";
	var WOFF = "woff";
	var WOFF2 = "woff2";
	var EOT = "eot";
	var SVG = "svg";
}
