package objects.ui;

class HealthBar extends ImageBar
{
	public function new()
	{
		super('health');
		max = 2;
		value = 1;
		rightToLeft = true;
	}
}
