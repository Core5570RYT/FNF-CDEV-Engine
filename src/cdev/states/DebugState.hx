package cdev.states;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.tweens.FlxEase;
import cdev.objects.play.hud.HealthIcon;
import flixel.util.FlxColor;
import cdev.objects.Bar;
import flixel.FlxObject;
import cdev.backend.Chart;
import cdev.backend.objects.Camera;
import cdev.objects.play.hud.RatingSprite;
import cdev.objects.play.Character;
import cdev.backend.audio.SoundGroup;
import cdev.objects.play.notes.NoteLoader;
import cdev.objects.play.notes.StrumLine;
import cdev.objects.play.notes.Note;

/**
 * hi myself pls tidy up this state's code dang it
 */

class DebugState extends State {
    var playerStrums:StrumLine;
    var opponentStrums:StrumLine;
    var sounds:SoundGroup;

    var noteLoader:NoteLoader;

    var playerChar:Character;
    var opponentChar:Character;
    var spectatorChar:Character;

    var iconP1:HealthIcon;
    var iconP2:HealthIcon;

    var ratingSprite:RatingSprite;

    var camGame:Camera;
    var camHUD:Camera;

    var chart:Chart;

    var defaultCamZoom:Float = 1;
    var defaultHudZoom:Float = 1;

    var camFollow:FlxObject;
    var followTarget:Character;
    
    var combo:Int = 0;

    var healthBar:Bar;
    var health(default,set):Float = 0.5;

    var scoreTxt:Text;
    function set_health(val:Float) {
        return health = FlxMath.bound(val,0,1);
    }
    var healthLerp:Float = 0.5;

    var score:Int = 0;
    var accuracy:Float = 0;
    var misses:Int = 0;

    var totalNotes:{hit:Float,all:Float} = {
        hit: 0.0,
        all: 0.0
    }

    var hitCount:{sick:Int, good:Int, bad:Int, shit:Int} = {
        sick:0, 
        good:0, 
        bad :0, 
        shit:0, 
    }

    override function create() {    
        initGame();
        initHUD();

        sounds.play();
        super.create();
    }

    function initGame() {
        /// Initialize Camera Objects ///
        camGame = new Camera();
		FlxG.cameras.reset(camGame);

		camHUD = new Camera();
        camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

        camFollow = new FlxObject(0,0,1,1);
        add(camFollow);

        camGame.follow(camFollow);
        
        /// Load Song Data, and SoundGroup ///
        var song = Utils.loadSong("Roses Erect", "hard");      
        chart = song.chart;  
                
        sounds = new SoundGroup(song.inst,song.voices);
        add(sounds);

        /// Init Conductor ///
        Conductor.current.updateBPM(chart.info.bpm);
        Conductor.current.onBeatTick.add(onBeatHit);

        /// Load Stage ///
        initStage();
    }
    
    function initStage() {
        defaultCamZoom = 0.9;
        var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Assets.image('stageback'));
        bg.scrollFactor.set(0.9, 0.9);
        bg.active = false;
        add(bg);

        var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Assets.image('stagefront'));
        stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
        stageFront.updateHitbox();
        stageFront.scrollFactor.set(0.9, 0.9);
        stageFront.active = false;
        add(stageFront);

        var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Assets.image('stagecurtains'));
        stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
        stageCurtains.updateHitbox();
        stageCurtains.scrollFactor.set(1.3, 1.3);
        stageCurtains.active = false;

        add(stageCurtains);

        spectatorChar = new Character(400,130,"gf",false);
        add(spectatorChar);

        playerChar = new Character(770,100,"bf",true);
        add(playerChar);

        opponentChar = new Character(100,100,"dad",false);
        add(opponentChar);
    }

    function initHUD() {
        /// Positioning and stuff ///
        var _strumCount:Float = 2;
        var _strumWidth:Float = Note.scaleWidth*Note.directions.length;

        var _maxPlayField:Float = FlxG.width / _strumCount;
        var _centerX:Float = (_maxPlayField-_strumWidth)*0.5;

        var up:Float = 60;
        var down:Float = (FlxG.height-Note.scaleWidth)-up;

        var _data = {
            strum: {
                yPos: (Preferences.downscroll ? down : up),
                scrollMult: (Preferences.downscroll ? -1 : 1)
            },
            healthBar: {
                y: (Preferences.downscroll ? 70 : FlxG.height - 90)
            }
        }

        /// Load Strums and NoteLoader ///
        opponentStrums = new StrumLine(_centerX,_data.strum.yPos,true);
        opponentStrums.scrollMult = _data.strum.scrollMult;
        opponentStrums.cameras = [camHUD];
        opponentStrums.characters.push(opponentChar);
        add(opponentStrums);
        
        playerStrums = new StrumLine((FlxG.width*0.5)+_centerX,_data.strum.yPos,false);
        playerStrums.scrollMult = _data.strum.scrollMult;
        playerStrums.cameras = [camHUD];
        playerStrums.characters.push(playerChar);
        playerStrums.onNoteHit.add(onNoteHit);
        playerStrums.onNoteMiss.add(onNoteMiss);
        add(playerStrums);

        // Remember to always put NoteLoader after initializing player and opponent strums.
        noteLoader = new NoteLoader([opponentStrums, playerStrums],chart);
        noteLoader.onEventSignal.add(onEvent);
        add(noteLoader);

        /// Load Health bar and icons ///
        healthBar = new Bar(0,_data.healthBar.y,Assets.image("hud/healthBar"),()->{return healthLerp;});
        healthBar.setColors(opponentChar.getBarColor(), playerChar.getBarColor());
        healthBar.cameras = [camHUD];
        healthBar.screenCenter(X);
        healthBar.leftToRight = false;
        add(healthBar);
        
        iconP1 = new HealthIcon(playerChar.icon, true);
        iconP1.cameras = [camHUD];
        add(iconP1);

        iconP2 = new HealthIcon(opponentChar.icon, false);
        iconP2.cameras = [camHUD];
        add(iconP2);

        /// Load Score Text ///
        scoreTxt = new Text(0,healthBar.y + healthBar.height + 20, "");
        scoreTxt.enableBG = true;
        scoreTxt.bgPadding = 5;
        scoreTxt.cameras = [camHUD];
        add(scoreTxt);

        /// Load Rating Sprite ///
        ratingSprite = new RatingSprite(FlxG.width*0.5, FlxG.height*0.5);
        ratingSprite.cameras = [camHUD];
        add(ratingSprite);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        _updateCameras(elapsed);

        _updateHUD(elapsed);

        if (FlxG.keys.justPressed.B) {
            playerStrums.cpu = !playerStrums.cpu;
        }

        if (FlxG.keys.justPressed.Q) {
            banger = !banger;
        }

        if (FlxG.keys.pressed.Z)
            sounds.speed *= 0.99;
        if (FlxG.keys.pressed.X)
            sounds.speed *= 1.01;
    }

    function _updateHUD(elapsed:Float) {
        // Update Score Text // 
        scoreTxt.screenCenter(X);
        accuracy = FlxMath.roundDecimal((totalNotes.hit / totalNotes.all)*100, 2);
        if (Math.isNaN(accuracy)) 
            accuracy = 0;
        var rank = Utils.getAccuracyRank(accuracy);
        var rankText:String = '#${rank.rating}#, ${Utils.getGameplayStatus(hitCount.sick,hitCount.good,hitCount.bad,hitCount.shit,misses)}';
        var scoreText:String = 'Misses: ${misses} // Score: ${Utils.formatNumber(score)} // Accuracy: ${accuracy}% [${Utils.getAccuracyRating(accuracy)} - $rankText]';
        scoreTxt.applyMarkup(scoreText, [
            new FlxTextFormatMarkerPair(new FlxTextFormat(rank.color),"#")
        ]);

        // Update Icons //
        _updateIcons(elapsed);
    } 

    var posVal:Float = 0;
    var moveTime:Float = 0;
    function _updateCameras(elapsed:Float) {
        camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, 1-(elapsed*6));
        camHUD.zoom = FlxMath.lerp(defaultHudZoom, camHUD.zoom, 1-(elapsed*6));

        if (followTarget != null) {
            var followX:Float = (followTarget.getMidpoint().x + 100) + (followTarget.isPlayer ? -followTarget.data.camera_offset.x : followTarget.data.camera_offset.x);
            var followY:Float = (followTarget.getMidpoint().y - 100) + followTarget.data.camera_offset.y;
            camFollow.x = FlxMath.lerp(followX, camFollow.x, 1-(elapsed*6));
            camFollow.y = FlxMath.lerp(followY, camFollow.y, 1-(elapsed*6));    
        }
    }

    var healthBarPercent:Float = 50;
    function _updateIcons(elapsed:Float) {
        healthLerp = FlxMath.lerp(health, healthLerp, 1 - (elapsed * 15));
		// Smooth health bar value
		healthBarPercent = FlxMath.lerp(healthBar.percent, healthBarPercent, 1 - (elapsed * 15));
        
        var zoomAdd:Float = 0.34;
        var beatEase:Float = (1 - FlxEase.quartOut((Conductor.current.time % Conductor.current.beat_ms) / Conductor.current.beat_ms)) * zoomAdd;
        var scaleLerp:Float = 1 + beatEase;

        if (iconP1.allowBeat)
            iconP1.scale.set(scaleLerp, scaleLerp);
        iconP1.updateHitbox();

        if (iconP2.allowBeat)
            iconP2.scale.set(scaleLerp, scaleLerp);
        iconP2.updateHitbox();

        var iconOffset:Float = 5;
        iconP1.x = (healthBar.progressCenter + (150/2)) - (150/2) + (iconOffset);
        iconP2.x = (healthBar.progressCenter - (150/2)) - (150/2 + iconOffset);

        iconP1.y = healthBar.y + (healthBar.height - 150)*0.5;
        iconP2.y = healthBar.y + (healthBar.height - 150)*0.5;

		var hbp:Float = healthBarPercent;
		var curP1Icon:Int = (hbp > 80) ? (iconP1.hasWinningIcon ? 2 : 0) : (hbp < 20 ? 1 : 0);
		var curP2Icon:Int = (hbp < 20) ? (iconP2.hasWinningIcon ? 2 : 0) : (hbp > 80 ? 1 : 0);

		iconP1.changeFrame(curP1Icon);
		iconP2.changeFrame(curP2Icon);
    }


    public function onEvent(event:ChartEvent) {
        switch (event.name) {
            case "Change Camera Focus":
                switch (event.args[0]){
                    case "dad": followTarget = cast opponentChar;
                    case "bf": followTarget = cast playerChar;
                }
        }
    }

    public function onNoteHit(note:Note) {
        combo++;
        switch (note.judgement.rating) {
            case SICK: hitCount.sick++;
            case GOOD: hitCount.good++;
            case BAD:  hitCount.bad++;
            case SHIT: hitCount.shit++;
        }
        appendNoteStatus(note);
        ratingSprite.show(note.judgement.rating,combo);
        totalNotes.all++;
    }

    public function onNoteMiss(note:Note) {
        combo = 0;
        appendNoteStatus(note);
        misses++;
        totalNotes.all++;
    }

    public function appendNoteStatus(note:Note) {
        health += note.judgement.health;
        score += note.judgement.score;
        totalNotes.hit += note.judgement.accuracy;
    }

    var banger:Bool = false;
    public function onBeatHit(beats:Int) {
        inline function _addZoom(zoom:Float)
        {
            camGame.zoom += (zoom * 0.5) * camGame.zoom;
            camHUD.zoom += (zoom) * camHUD.zoom;
        }
        if (beats % (banger ? 1 : 4) == 0) {
            _addZoom(0.05);
        }
        playerChar.dance();
        opponentChar.dance();
        spectatorChar.dance();
    }
}