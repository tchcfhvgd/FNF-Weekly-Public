package meta.states.substate;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import gameObjects.*;
import meta.states.*;
import meta.data.*;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var hasStartedDeathSound:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var video:Null<PsychVideoSprite> = null;
	public static var isVideo:Bool = false;

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';

		video = null;
		isVideo = false;
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnScripts('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		PlayState.instance.setOnScripts('inGameOver', true);

		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	public function setGameOverVideo(name:String) // called in hscript
	{
		isVideo = true;

		endSoundName = "empty";
		deathSoundName = "empty";
		loopSoundName = "empty";

		boyfriend.visible = false;

		video = new PsychVideoSprite();

		video.addCallback('onFormat',()->{
			video.setGraphicSize(0, FlxG.height);
			video.updateHitbox();
			video.screenCenter();
			video.antialiasing = true;
			video.cameras = [PlayState.instance.camOther];
		});
		video.addCallback('onEnd',()->{
			FlxG.resetState();
		});

		video.load(Paths.video(name));
		video.play();
		add(video);
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		PlayState.instance.callOnScripts('onUpdate', [elapsed]);
		PlayState.instance.callOnHScripts('update', [elapsed]);
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);

		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		for (touch in FlxG.touches.list)
		{
		if (controls.ACCEPT || touch.justPressed)
		{
			endBullshit();
		}
		}

		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			if(PlayState.isStoryMode) Init.SwitchToPrimaryMenu(WeeklyMainMenuState);
			else Init.SwitchToPrimaryMenu(FreeplayState);

			FlxG.sound.playMusic(Paths.music(KUTValueHandler.getMenuMusic()));
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if (!hasStartedDeathSound) {
				if (deathSoundName != 'empty') FlxG.sound.play(Paths.sound(deathSoundName));
				hasStartedDeathSound = true;
			}

			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished)
			{			
				coolStartDeath();
				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		//FlxG.log.add('beat');
	}

	public var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		PlayState.instance.callOnScripts('deathAnimStart', [volume]);

		if (loopSoundName != 'empty')
			FlxG.sound.playMusic(Paths.music(loopSoundName), volume);

		PlayState.instance.callOnScripts('deathAnimStartPost', [volume]);
		
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			
			if (isVideo) MusicBeatState.resetState();

			else {
				boyfriend.playAnim('deathConfirm', true);
				FlxG.sound.music.stop();
				if (endSoundName != 'empty')
					FlxG.sound.play(Paths.music(endSoundName));
				new FlxTimer().start(0.7, function(tmr:FlxTimer)
				{
					FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
					{
						MusicBeatState.resetState();
					});
				});
				PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
			}
			
		}
	}
}
