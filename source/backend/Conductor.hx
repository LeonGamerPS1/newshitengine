package backend;

import lime.app.Event;

typedef SongTmPoint =
{
    var time:Float;
    var bpm:Float;
    @:optional var step:Float;
}

class Conductor
{
    public static var safeFrames:Int = 10;
    public static var sfz:Float = (safeFrames / 60) * 1000; 
    public static var timeChanges:Array<SongTmPoint> = [];

    public static var time(default, set):Float = 0;
    public static var bpm(default, set):Float = 100;
    
    public static var beatLength:Float = (60 / 100) * 1000; // 600ms
    public static var stepLength:Float = 150; // 600 * 0.25
    public static var measureLength:Float = 2400; // 600 * 4

    public static var curStep:Float = 0;
    public static var curBeat:Float = 0;
    public static var curSection:Float = 0;

    public static var onStep:Event<Int->Void> = new Event<Int->Void>();
    public static var onBeat:Event<Int->Void> = new Event<Int->Void>();
    public static var onMeasure:Event<Int->Void> = new Event<Int->Void>();

	public static var offset = 0.0;

    /**
     * Setzt den Conductor komplett zurück.
     * Muss vor dem Laden eines neuen Songs aufgerufen werden!
     */
    public static function reset()
    {
        timeChanges = [];
        time = 0;
        bpm = 100;
        
        curStep = 0;
        curBeat = 0;
        curSection = 0;
        
        beatLength = (60 / 100) * 1000;
        stepLength = beatLength / 4;
        measureLength = beatLength * 4;
    }


    public static function addTimeChangeAt(time:Float, bpm:Float)
    {
        var change:SongTmPoint = {time: time, bpm: bpm, step: 0};
        timeChanges.push(change);
        
        // Berechnet die internen Step-Änderungen neu
        mapBPMChanges();
    }

    public static function mapBPMChanges()
    {
        if (timeChanges.length == 0) return;
        
        // Sortierung nach Songzeit
        timeChanges.sort(function(a, b) return Std.int(a.time - b.time));

        var totalSteps:Float = 0;
        var lastTime:Float = 0;
        var lastBpm:Float = bpm;

        for (i in 0...timeChanges.length)
        {
            var change = timeChanges[i];
            var delta = change.time - lastTime;
            var lastStepLength = ((60 / lastBpm) * 1000) / 4;
            
            totalSteps += delta / lastStepLength;
            change.step = totalSteps;
            
            lastTime = change.time;
            lastBpm = change.bpm;
        }
    }

    /**
     * Gibt den BPM-Wechselpunkt zurück, der zu einer bestimmten Songzeit aktiv ist.
     */
    public static function getTimeChangeAt(time:Float):SongTmPoint
    {
        var lastTimeChange:SongTmPoint = {time: 0, bpm: bpm, step: 0};
        
        for (timeChange in timeChanges)
        {
            if (timeChange.time <= time)
                lastTimeChange = timeChange;
            else 
                break;
        }
        
        return lastTimeChange;
    }

    static function set_time(value:Float):Float
    {
        time = value;
        update(time);
        return time;
    }

    public static function update(time:Float)
    {
        var flo = Math.floor;

        var lastStep = curStep;
        var lastBeat = curBeat;
        var lastSec = curSection;

        updateTimeValues(time);

        if (flo(curStep) != flo(lastStep))
            onStep.dispatch(flo(curStep));

        if (flo(curBeat) != flo(lastBeat))
            onBeat.dispatch(flo(curBeat));

        if (flo(curSection) != flo(lastSec))
            onMeasure.dispatch(flo(curSection));
    }

    private static function updateTimeValues(time:Float)
    {
        var activeChange:SongTmPoint = getTimeChangeAt(time);

        if (bpm != activeChange.bpm) {
            bpm = activeChange.bpm; 
        }

        var timePassed = time - activeChange.time;
        
        // Fortschritt berechnen: Letzter bekannter Step + vergangene Zeit / Step-Länge
        curStep = activeChange.step + (timePassed / stepLength);
        curBeat = curStep / 4;
        curSection = curBeat / 4; 
    }

    static function set_bpm(value:Float):Float
    {
        bpm = value;
        beatLength = (60 / bpm) * 1000;
        stepLength = (beatLength / 4);
        measureLength = (beatLength * 4);
        return bpm;
    }
}
