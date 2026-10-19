#if !macro
import backend.Conductor;
import backend.Paths;
import backend.Util;
import backend.input.Controls.*;
import flixel.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.*;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxShader;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.*;
import flixel.util.FlxTimer;
import haxe.Json;
import haxe.ds.StringMap;
import openfl.Assets as OpenFLAssets;
import states.*;
#end

using StringTools;
