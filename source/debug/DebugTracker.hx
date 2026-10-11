package debug;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

typedef TrackValue = {
	var displayName:String;
	var valueFunc:Void->Dynamic;
}

typedef TrackValueSection = {
	var secname:String;
	var trackvals:Array<TrackValue>;
}

class DebugTracker extends Sprite
{
	private var sections:Array<TrackValueSection>;
	private var sectionContainers:Array<Sprite>;
	private var textFields:Array<TextField>;
	private var lastStrings:Array<String>; // Track changes to avoid redraws
	private var textColor:Int;
	
	private final padding:Float = 8; 
	private final spacing:Float = 10;
	private final cornerRadius:Float = 12; 

	public function new(inX:Float, inY:Float, textColor:Int = 0xFFFFFF, ?initialSections:Array<TrackValueSection>)
	{
		super();
		
		this.x = inX;
		this.y = inY;
		this.textColor = textColor;
		
		this.sections = [];
		this.sectionContainers = [];
		this.textFields = [];
		this.lastStrings = [];

		if (initialSections != null)
		{
			for (section in initialSections)
			{
				addSection(section.secname, section.trackvals);
			}
		}

		addEventListener(Event.ENTER_FRAME, onEnter);
	}

	public function addSection(name:String, ?values:Array<TrackValue>)
	{
		var newSection:TrackValueSection = {
			secname: name,
			trackvals: (values != null) ? values : []
		};
		
		sections.push(newSection);
		lastStrings.push(""); // Initialize empty state

		var container = new Sprite();
		addChild(container);
		sectionContainers.push(container);

		var tf = new TextField();
		tf.x = padding;
		tf.y = padding;
		tf.selectable = false;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.defaultTextFormat = new TextFormat("_typewriter", 12, textColor);
		container.addChild(tf);
		textFields.push(tf);

		var index = sections.length - 1;
		
		// Force initial layout pass
		var initialText = getSectionTextString(index);
		tf.text = initialText;
		lastStrings[index] = initialText;
		
		drawBackground(container, tf);
		repositionAll();
	}

	private function repositionAll()
	{
		var currentY:Float = 0;
		for (container in sectionContainers)
		{
			container.y = currentY;
			currentY += container.height + spacing;
		}
	}

	// Separated string generation from UI application
	private function getSectionTextString(index:Int):String
	{
		var section = sections[index];
		var output:String = "[" + section.secname + "]";
		for (trackVal in section.trackvals)
		{
			var val:Dynamic = "N/A";
			if (trackVal.valueFunc != null)
			{
				try {
					val = trackVal.valueFunc();
				} catch(e:Dynamic) {
					val = "ERROR";
				}
			}
			output += "\n" + trackVal.displayName + ": " + val;
		}
		return output;
	}

	private function drawBackground(container:Sprite, tf:TextField)
	{
		var g = container.graphics;
		g.clear();
		g.beginFill(0x000000, 0.5);
		g.drawRoundRect(0, 0, tf.width + (padding * 2), tf.height + (padding * 2), cornerRadius, cornerRadius);
		g.endFill();
	}

	private function onEnter(_)
	{
		if (!visible || sections.length == 0) return;

		var needsReposition = false;

		for (i in 0...sections.length)
		{
			var newText = getSectionTextString(i);
			
			// CRITICAL FIX: Only touch UI objects if the underlying text changed
			if (newText != lastStrings[i])
			{
				lastStrings[i] = newText;
				textFields[i].text = newText;
				drawBackground(sectionContainers[i], textFields[i]);
				needsReposition = true;
			}
		}
		
		// Only run layout logic if at least one container changed dimensions
		if (needsReposition)
		{
			repositionAll();
		}
	}
}
