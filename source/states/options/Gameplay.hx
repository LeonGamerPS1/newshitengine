package states.options;

import objects.ui.Option;

class Gameplay extends BaseOptionCat
{
	override function create()
	{
        super.create();
		addOption('downscroll', new Option('downscroll', BOOL));
		addOption('middlescroll', new Option('middlescroll', BOOL));
		addOption('offset', new Option('offset', INT(-9000, 9000, 10)));
	}
}
