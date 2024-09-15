package meta.modding.chart_editor;

import flixel.graphics.frames.FlxAtlasFrames;
import game.objects.Note;

/**
 * A dummy note that's used on the Chart Editor
 */
class ChartNote extends FlxSprite {
    public static var CACHED_GRAPHIC:FlxAtlasFrames = null;
    public var strumTime:Float = 0;
    public var noteData:Int = 0;
    public var holdLength:Float = 0;
    public var noteType:String = "Default Note";
    public var noteArgs:Array<String> = ["",""];

    public var rawData:Array<Dynamic> = [0,0,0,"Default Note", ["",""]];

    public var isSustain:Bool = false;

    public var nLabelOv:FlxText = null;
    public var nSustain:ChartNote = null;
    public var nSustainEnd:ChartNote = null;
    public var bgHighlight:FlxSprite = null;

    public var asDummyNote:Bool = false;
    public var isSelected:Bool = false;

    public var animData:Int = 0;

    public var dontDraw:Bool = false;

    public function new(nX:Float = 0, nY:Float = 0)
    {
        super(nX,nY);
        if (ChartNote.CACHED_GRAPHIC == null) {
            ChartNote.CACHED_GRAPHIC = Paths.getSparrowAtlas("notes/NOTE_assets");
        }
        bgHighlight = new FlxSprite().makeGraphic(ChartEditor.grid_size,1,FlxColor.WHITE);
        bgHighlight.active = false;
    }

    /**
     * Start initializing the note.
     * @param noteArray Note array from CDevChart's `notes` array.
     * @return 
     */
    public function init(noteArray:Array<Dynamic>, isSustain:Bool, ?parent:ChartNote){
        strumTime = noteArray[0];
        animData = noteData = noteArray[1];
        holdLength = noteArray[2];
        if (noteArray[3] != null)
            noteType = noteArray[3];
        if (noteArray[4] != null)
            noteArgs = noteArray[4];
        rawData = noteArray;

        this.isSustain = isSustain;

        if (parent != null) 
            frames = parent.frames;
        else 
            frames = ChartNote.CACHED_GRAPHIC;//Paths.getSparrowAtlas("notes/NOTE_assets");

        var i:String = Note.directions[noteData%4];
        if (!asDummyNote) {
            animation.addByPrefix(i+"anim", i+"0", 24);
        } else {
            for (o in Note.directions)
                animation.addByPrefix(o+"anim", o+"0", 24);
        }

        if (isSustain) {
            animation.addByPrefix("end"+i, (i == "purple" ? "pruple end hold" : i+" hold end"), 24);
            animation.addByPrefix("hold"+i, i+" hold piece", 24);
        }

        antialiasing = CDevConfig.saveData.antialiasing;
        setGraphicSize(ChartEditor.grid_size,ChartEditor.grid_size);
        updateHitbox();

        if (!isSustain){
            nSustain = new ChartNote();
            nSustain.init([strumTime + Conductor.stepCrochet,noteData, 0, noteType, noteArgs], true, this);
            nSustain.setGraphicSize(ChartEditor.grid_size/2.5, Std.int(ChartEditor.grid_size*((holdLength-(Conductor.stepCrochet*2)) / Conductor.stepCrochet)));
            nSustain.updateHitbox();

            nSustainEnd = new ChartNote();
            nSustainEnd.init([Conductor.stepCrochet,noteData, 0, noteType, noteArgs], true, this);
            nSustainEnd.setGraphicSize(ChartEditor.grid_size/2.5, Std.int(ChartEditor.grid_size/1.8));
            nSustainEnd.updateHitbox();

            nSustain.active = nSustainEnd.active = false;

            if (noteType != "Default Note") {
                nLabelOv = new FlxText(0,0,-1,"",30);
                nLabelOv.setFormat(FunkinFonts.VCR, 22, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
                nLabelOv.borderSize = 1.5;
            }
        }
    }

    override function draw():Void {
        if (asDummyNote){
            bgHighlight.x = x;
            bgHighlight.y = y+(bgHighlight.height*bgHighlight.scale.y)/2;
            bgHighlight.alpha = alpha * 0.5;
            bgHighlight.setGraphicSize(ChartEditor.grid_size, height);
            bgHighlight.draw();
        }

        if (!dontDraw) {
            if (!isSustain && holdLength > 0) {
                nSustain.x = x + (width - nSustain.width) * 0.5;
                nSustain.y = y + ChartEditor.grid_size;
                nSustain.alpha = alpha*0.7;
                nSustain.animation.play("hold"+Note.directions[animData%4], true);
                nSustain.setGraphicSize(ChartEditor.grid_size/2.5, Std.int(ChartEditor.grid_size*((holdLength-(Conductor.stepCrochet*2)) / Conductor.stepCrochet)));
                nSustain.updateHitbox();
                nSustain.draw();
    
                nSustainEnd.x = nSustain.x;
                nSustainEnd.y = Math.floor(nSustain.y + nSustain.height);
                nSustainEnd.alpha = nSustain.alpha;
                nSustainEnd.animation.play("end"+Note.directions[animData%4], true);
                nSustainEnd.setGraphicSize(ChartEditor.grid_size/2.5, Std.int(ChartEditor.grid_size/1.8));
                nSustainEnd.updateHitbox();
                nSustainEnd.draw();
            }
    
            if (!isSustain){
                animation.play(Note.directions[animData%4]+"anim",true);
            }
            super.draw();
    
            if (!isSustain && noteType != "Default Note") {
                var data:Int = ChartEditor.current.getNoteTypePos(noteType);
                nLabelOv.text = (data != -1 ? '${data}' : "");
                nLabelOv.y = y + (height - nLabelOv.height)*0.5;
                nLabelOv.x = x + (width - nLabelOv.width)*0.5;
                nLabelOv.alpha = alpha;
                nLabelOv.draw();
            }
    
    
            if (!asDummyNote && isSelected){
                bgHighlight.x = x;
                bgHighlight.y = y+(bgHighlight.height*bgHighlight.scale.y)/2;
                bgHighlight.alpha = alpha * 0.5;
                bgHighlight.setGraphicSize(ChartEditor.grid_size, height+(!isSustain && holdLength>0?nSustain.height+nSustainEnd.height:0));
                bgHighlight.color = CDevConfig.utils.CDEV_ENGINE_BLUE;
                bgHighlight.draw();
            }
        }
    }

    override function destroy() {
        if (nSustain != null)
            nSustain.destroy();
        if (nSustainEnd != null)
            nSustainEnd.destroy();
        if (bgHighlight != null)
            bgHighlight.destroy();
        if (nLabelOv != null)
            nLabelOv.destroy();
        super.destroy();
    }
}