#if !macro
import backend.Conductor;
import backend.input.Controls.inputSystem;
import flixel.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.*;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxShader;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.*;
import flixel.util.FlxTimer;
import openfl.Assets as OpenFLAssets;
#end
import backend.Paths;
import haxe.Json;
import haxe.ds.StringMap;
import states.*;

using StringTools;
