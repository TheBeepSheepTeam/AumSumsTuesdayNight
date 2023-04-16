package;

import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUI;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.Lib;
import flixel.FlxBasic;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecimalBeat:Float = 0;

	public static var currentColor = 0;
	public static var switchingState:Bool = false;

	private var assets:Array<FlxBasic> = [];

	public static var initSave:Bool = false;

	private var controls(get, never):Controls;
	var fullscreenBind:FlxKey;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.75, true));
		}
		fullscreenBind = FlxKey.fromString(Std.string(FlxG.save.data.fullscreenBind));
		FlxTransitionableState.skipNextTransOut = false;

		super.create();
		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
	}

	override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic
	{
		var result = super.remove(Object, Splice);
		return result;
	}

	public function clean()
	{
		if (FlxG.save.data.optimize)
		{
			for (i in assets)
			{
				remove(i);
			}
		}
	}

	public function destroyObject(Object:Dynamic):Void
	{
		if (Std.isOfType(Object, FlxSprite))
		{
			var spr:FlxSprite = cast(Object, FlxSprite);
			spr.kill();
			remove(spr, true);
			spr.destroy();
			spr = null;
		}
		else if (Std.isOfType(Object, FlxTypedGroup))
		{
			var grp:FlxTypedGroup<Dynamic> = cast(Object, FlxTypedGroup<Dynamic>);
			for (ObjectGroup in grp.members)
			{
				if (Std.isOfType(ObjectGroup, FlxSprite))
				{
					var spr:FlxSprite = cast(ObjectGroup, FlxSprite);
					spr.kill();
					remove(spr, true);
					spr.destroy();
					spr = null;
				}
			}
		}
	}

	override function destroy()
	{
		super.destroy();
	}

	public function fancyOpenURL(schmancy:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [schmancy, "&"]);
		#else
		FlxG.openURL(schmancy);
		#end
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Std.isOfType(Object, FlxUI))
			return null;

		if (Std.isOfType(Object, FlxSprite))
			var spr:FlxSprite = cast(Object, FlxSprite);

		// Debug.logTrace(Object);
		assets.push(Object);
		var result = super.add(Object);
		return result;
	}

	var oldStep:Int = 0;

	override function update(elapsed:Float)
	{
		if (curDecimalBeat < 0)
			curDecimalBeat = 0;

		if (Conductor.songPosition < 0)
			curDecimalBeat = 0;
		else
		{
			var data = null;

			data = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);

			if (data != null)
			{
				FlxG.watch.addQuick("Current Conductor Timing Seg", data.bpm);

				curDecimalBeat = data.startBeat + ((((Conductor.songPosition / 1000)) - data.startTime) * (data.bpm / 60));

				curBeat = Math.floor(curDecimalBeat);
				curStep = Math.floor(curDecimalBeat * 4);

				if (oldStep != curStep)
				{
					stepHit();
					oldStep = curStep;
				}

				Conductor.crochet = ((60 / data.bpm) * 1000) / PlayState.songMultiplier;
			}
			else
			{
				curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);

				curBeat = Math.floor(curDecimalBeat);
				curStep = Math.floor(curDecimalBeat * 4);

				if (oldStep != curStep)
				{
					stepHit();
					oldStep = curStep;
				}

				Conductor.crochet = ((60 / Conductor.bpm) * 1000) / PlayState.songMultiplier;
			}
		}

		if (FlxG.keys.anyJustPressed([fullscreenBind]))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		super.update(elapsed);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	public static function switchState(nextState:FlxState)
	{
		MusicBeatState.switchingState = true;
		// Custom made Trans in
		Main.mainClassState = Type.getClass(nextState);
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.4, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					MusicBeatState.switchingState = false;
					FlxG.resetState();
				};
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					MusicBeatState.switchingState = false;
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}
}
