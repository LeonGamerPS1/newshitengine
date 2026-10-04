package shaders;

class RGB extends FlxShader
{
	@:glFragmentSource("

    // @author https://github.com/ADA-Funni
#pragma header

uniform vec3 red;
uniform vec3 green;
uniform vec3 blue;

void main() {
  vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
  
  // Erstellt eine 3x3 Matrix aus den Farbvektoren und multipliziert sie in einem Rutsch
  mat3 colorMatrix = mat3(red, green, blue);
  
  gl_FragColor = vec4(colorMatrix * color.rgb, color.a);
}

    ")
	public function new(r:FlxColor = FlxColor.RED, g:FlxColor = FlxColor.GREEN, b:FlxColor = FlxColor.BLUE)
	{
		super();
		red.value = [1, 0, 0];
		green.value = [0, 1, 0];
		blue.value = [0, 0, 1];

        this.r = r;
        this.g = g;
        this.b = b;
	}

	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;

	public function copyFrom(rs:RGB)
	{
		r = rs.r;
		g = rs.g;
		b = rs.b;
	}

	public function copyTo(ts:RGB)
	{
		ts.r = r;
		ts.g = g;
		ts.b = b;
	}

	function set_r(value:FlxColor):FlxColor
	{
		red.value = [value.redFloat, value.greenFloat, value.blueFloat];
		return r = value;
	}

	function set_g(value:FlxColor):FlxColor
	{
		green.value = [value.redFloat, value.greenFloat, value.blueFloat];
		return g = value;
	}

	function set_b(value:FlxColor):FlxColor
	{
		blue.value = [value.redFloat, value.greenFloat, value.blueFloat];
		return b = value;
	}
}
