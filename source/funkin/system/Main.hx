package funkin.system;

import funkin.windows.WindowsAPI;
import funkin.menus.TitleState;
import funkin.game.Highscore;
import funkin.options.Options;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

#if sys
import sys.io.File;
#end
// TODO: REMOVE TEST
import funkin.mods.ModsFolder;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if !debug
		initialState = TitleState;
		#end


		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));

		loadGameSettings();
		
		#if !mobile
		addChild(new FPS(10, 3, 0xFFFFFF));
		#end
	}

	@:dox(hide)
	public static var audioDisconnected:Bool = false;
	
	public static var changeID:Int = 0;
	@:dox(hide)
	@:noCompletion
	private function onStateSwitch(state:FlxState):Void {
		#if windows
			if (audioDisconnected) {
				// for(e in lime.media.openal.AL.buffers) {
				// 	lime.media.openal.AL.deleteBuffer(e);
				// }
				// lime.media.openal.AL.buffers = [];
				// var buffers = [for(e in lime._internal.backend.native.NativeAudioSource.initBuffers) e];
				// trace(buffers.length);

				for(e in FlxG.sound.list) {
					e.stop();
				}
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
				
				#if !lime_doc_gen
				if (lime.media.AudioManager.context.type == OPENAL)
				{
					var alc = lime.media.AudioManager.context.openal;

					var device = alc.openDevice();
					var ctx = alc.createContext(device);
					alc.makeContextCurrent(ctx);
					alc.processContext(ctx);
				}
				#end
				changeID++;
				
				// for(e in buffers) {
				// 	@:privateAccess
				// 	e.init();
				// }

				// lime._internal.backend.native.NativeAudioSource.initBuffers = [];
				audioDisconnected = false;
			}
		#end
	}

	public function loadGameSettings() {
		funkin.options.PlayerSettings.init();
		FlxG.save.bind('Save');
		Highscore.load();

		ModsFolder.init();
		ModsFolder.loadMod("introMod");
		ModsFolder.currentModFolder = "introMod";

		#if sys
		if (Sys.args().contains("-livereload")) {
			trace("Used lime test windows. Switching into source assets.");
			ModsFolder.loadLibraryFromFolder('sourceassets', './../../../../assets/');
			@:privateAccess
			Paths.__useSourceAssets = true;

			var buildNum:Int = Std.parseInt(File.getContent("./../../../../buildnumber.txt"));
			buildNum++;
			File.saveContent("./../../../../buildnumber.txt", Std.string(buildNum));
		}
		#end
		
		FlxG.fixedTimestep = false;
		FlxG.autoPause = false;

        FlxG.signals.preStateCreate.add(onStateSwitch);

		Options.load();

		WindowsAPI.registerAudio();
		// WindowsAPI.setAudioChangeCallback(function() {
		// 	trace("test");
		// });

		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, 0xFF000000, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, 0xFF000000, 0.7, new FlxPoint(0, 1),
			{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
	}
}
