package mikolka.vslice.ui;

import mikolka.vslice.freeplay.FreeplayState;
import mikolka.compatibility.ui.MainMenuHooks;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.ui.title.TitleState;
import mikolka.compatibility.ModsHelper;
import options.OptionsState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
#if !LEGACY_PSYCH
#if MODS_ALLOWED
import states.ModsMenuState;
#end
import states.CreditsState;
import states.AchievementsMenuState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end

// Main Menu estilo Doki Doki Takeover para P-Slice 3.4.2
// Reemplaza source/mikolka/vslice/ui/MainMenuState.hx
class MainMenuState extends MusicBeatState
{
	#if !LEGACY_PSYCH
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	#else
	public static var psychEngineVersion:String = '0.6.3'; // This is also used for Discord RPC
	#end
	public static var pSliceVersion:String = '3.4.2';
	public static var funkinVersion:String = '0.7.6'; // Version of funkin' we are emulationg

	// Se mantienen porque otras clases de P-Slice pueden usarlas
	var bg:FlxSprite;
	var magenta:FlxSprite;

	var stickerSubState:Bool;

	// ---- Config del menu DDTO ----
	var menuCharAtlas:String = 'menucharacters/dokitogetheralt';
	var menuCharPrefix:String = 'Doki together club';
	var menuFont:String = 'vcr.ttf'; // cambia por riffic.ttf si lo agregas a assets/fonts
	var bpm:Float = 120; // BPM de freakyMenu (120 = el de DDTO; usa 102 si dejas el de P-Slice)

	var curSelected:Int = 0;
	var menuItems:FlxTypedGroup<FlxText>;

	var optionShit:Array<String> = [
		'story mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options',
		'debug',
		'exit'
	];

	static var firstStart:Bool = true;

	var acceptInput:Bool = true;
	var selectedSomethin:Bool = false;
	var lastBeat:Int = -1;

	var backdrop:FlxBackdrop;
	var logo:FlxSprite;
	var logoBl:FlxSprite;
	var menu_character:FlxSprite;

	public function new(?stickers:Bool = false)
	{
		super();
		stickerSubState = stickers;
	}

	override function create()
	{
		if (stickerSubState)
			ModsHelper.clearStoredWithoutStickers();
		else
			CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();
		#if (debug && !LEGACY_PSYCH)
		FlxG.console.registerFunction("dumpCache", CacheSystem.cacheStatus);
		FlxG.console.registerFunction("dumpSystem", backend.Native.buildSystemInfo);
		#end

		ModsHelper.resetActiveMods();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;
		FlxG.mouse.visible = true;

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

		// Fondos originales de P-Slice (otras clases pueden usar bg/magenta)
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = VsliceOptions.ANTIALIASING;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = VsliceOptions.ANTIALIASING;
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		// Fondo que se desplaza (DDTO)
		var backdropGraphic = Paths.image('scrollingBG');
		if (backdropGraphic != null)
		{
			backdrop = new FlxBackdrop(backdropGraphic);
			backdrop.velocity.set(-40, -40);
			backdrop.antialiasing = VsliceOptions.ANTIALIASING;
			add(backdrop);
		}

		// Personaje del menu
		var charGraphic = Paths.image(menuCharAtlas);
		if (charGraphic != null)
		{
			menu_character = new FlxSprite(490, 50);
			menu_character.frames = Paths.getSparrowAtlas(menuCharAtlas);
			menu_character.scale.set(0.77, 0.77);
			menu_character.animation.addByPrefix('play', menuCharPrefix, 21, false);
			menu_character.antialiasing = VsliceOptions.ANTIALIASING;
			menu_character.updateHitbox();
			menu_character.animation.play('play');
			add(menu_character);
		}

		// Panel izquierdo
		var logoGraphic = Paths.image('Credits_LeftSide');
		if (logoGraphic != null)
		{
			logo = new FlxSprite(-260, 0).loadGraphic(logoGraphic);
			logo.antialiasing = VsliceOptions.ANTIALIASING;
			add(logo);
			if (firstStart)
				FlxTween.tween(logo, {x: -60}, 1.2, {ease: FlxEase.elasticOut});
			else
				logo.x = -60;
		}

		// Logo animado
		var logoBlGraphic = Paths.image('DDLCStart_Screen_Assets');
		if (logoBlGraphic != null)
		{
			logoBl = new FlxSprite(-160, -40);
			logoBl.frames = Paths.getSparrowAtlas('DDLCStart_Screen_Assets');
			logoBl.antialiasing = VsliceOptions.ANTIALIASING;
			logoBl.scale.set(0.5, 0.5);
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.animation.play('bump');
			logoBl.updateHitbox();
			add(logoBl);
			if (firstStart)
				FlxTween.tween(logoBl, {x: 40}, 1.2, {ease: FlxEase.elasticOut});
			else
				logoBl.x = 40;
		}

		// Opciones
		menuItems = new FlxTypedGroup<FlxText>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxText = new FlxText(-350, 330 + (i * 50), 0, optionShit[i].toUpperCase());
			menuItem.setFormat(Paths.font(menuFont), 27, FlxColor.WHITE, LEFT);
			menuItem.antialiasing = VsliceOptions.ANTIALIASING;
			menuItem.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFFFF7CFF, 2);
			menuItem.ID = i;
			menuItems.add(menuItem);

			if (firstStart)
				FlxTween.tween(menuItem, {x: 50}, 1.2 + (i * 0.2), {ease: FlxEase.elasticOut});
			else
				menuItem.x = 50;
		}
		firstStart = false;

		// Textos de version
		var psychVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, "Psych Engine " + psychEngineVersion, 12);
		var fnfVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, 'v${funkinVersion} (P-slice ${pSliceVersion})', 12);
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		psychVer.scrollFactor.set();
		fnfVer.scrollFactor.set();
		add(psychVer);
		add(fnfVer);

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			MainMenuHooks.unlockFriday();

		#if MODS_ALLOWED
		MainMenuHooks.reloadAchievements();
		#end
		#end

		changeItem(0);

		super.create();

		// Controles moviles de P-Slice
		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('UP_DOWN', 'A_B');
		#end
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		updateBeat();

		if (!selectedSomethin && acceptInput)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			// Mouse / toque
			var clicked:Bool = false;
			if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0 || FlxG.mouse.justPressed)
			{
				for (item in menuItems.members)
				{
					if (item != null && item.alive && FlxG.mouse.overlaps(item))
					{
						if (item.ID != curSelected)
						{
							curSelected = item.ID;
							FlxG.sound.play(Paths.sound('scrollMenu'));
							changeItem(0);
						}
						clicked = FlxG.mouse.justPressed;
						break;
					}
				}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}
			else if (controls.ACCEPT || clicked)
				selectThing();
		}

		super.update(elapsed);
	}

	function updateBeat()
	{
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			return;
		var crochet:Float = 60000 / bpm;
		var beat:Int = Math.floor(FlxG.sound.music.time / crochet);
		if (beat != lastBeat)
		{
			lastBeat = beat;
			onBeat(beat);
		}
	}

	function onBeat(beat:Int)
	{
		if (logoBl != null)
			logoBl.animation.play('bump', true);

		if (menu_character != null && beat % 2 == 0)
			menu_character.animation.play('play', true);
	}

	function changeItem(huh:Int = 0)
	{
		if (huh != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelected += huh;

		if (curSelected >= optionShit.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = optionShit.length - 1;

		menuItems.forEach(function(txt:FlxText)
		{
			if (txt.ID == curSelected)
				txt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFFFFCFFF, 2);
			else
				txt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFFFF7CFF, 2);
		});
	}

	function selectThing():Void
	{
		acceptInput = false;
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;

		menuItems.forEach(function(txt:FlxText)
		{
			if (curSelected != txt.ID)
			{
				FlxTween.tween(txt, {alpha: 0}, 1.3, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						txt.kill();
					}
				});
			}
			else
			{
				if (VsliceOptions.FLASHBANG)
				{
					FlxFlicker.flicker(txt, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						goToState();
					});
				}
				else
				{
					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						goToState();
					});
				}
			}
		});
	}

	function goToState()
	{
		var daChoice:String = optionShit[curSelected];

		switch (daChoice)
		{
			case 'story mode':
				MusicBeatState.switchState(new StoryMenuState());

			case 'freeplay':
				persistentDraw = true;
				persistentUpdate = false;
				// Freeplay tiene su propia transicion
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				openSubState(new FreeplayState());
				subStateOpened.addOnce(state ->
				{
					menuItems.forEach(function(txt:FlxText)
					{
						txt.revive();
						txt.alpha = 1;
						txt.visible = true;
					});
					selectedSomethin = false;
					acceptInput = true;
					changeItem(0);
				});

			#if MODS_ALLOWED
			case 'mods':
				MusicBeatState.switchState(new ModsMenuState());
			#end

			#if ACHIEVEMENTS_ALLOWED
			case 'awards':
				MusicBeatState.switchState(new AchievementsMenuState());
			#end

			case 'credits':
				MusicBeatState.switchState(new CreditsState());

			case 'options':
				goToOptions();

			case 'debug':
				MusicBeatState.switchState(new MasterEditorMenu());

			case 'exit':
				lime.system.System.exit(0);
		}
	}

	function goToOptions()
	{
		MusicBeatState.switchState(new OptionsState());
		#if !LEGACY_PSYCH OptionsState.onPlayState = false; #end
		if (PlayState.SONG != null)
		{
			PlayState.SONG.arrowSkin = null;
			PlayState.SONG.splashSkin = null;
			#if !LEGACY_PSYCH PlayState.stageUI = 'normal'; #end
		}
	}
}
