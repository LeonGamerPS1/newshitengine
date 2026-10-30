package objects.effects;

import animate.internal.RenderTexture;

class CameraCopySprite extends FlxSprite
{
	var _renderTexture:RenderTexture;

	public var copycam:FlxCamera;

	public function new(?copycam:FlxCamera)
	{
		super();
		copycam ??= FlxG.camera;
		this.copycam = copycam;
		_renderTexture = new RenderTexture(FlxG.width, FlxG.height);
		@:privateAccess
		_renderTexture._camera = copycam;
		width = 1280;
		height = 720;
		centerOffsets();
		centerOrigin();
		screenCenter();
	}

	override function drawComplex(c:FlxCamera)
	{
		final matrix = FlxSprite.drawComplexMatrix; // TODO: Just use local?
		prepareComplexMatrix(matrix, frame, c);
		_renderTexture.draw(this, c, matrix, colorTransform, blend, antialiasing, shader);
	}
}
