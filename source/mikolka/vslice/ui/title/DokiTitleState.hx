package mikolka.vslice.ui.title;

import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.ui.MainMenuState;

// Pantalla de titulo estilo Doki Doki Takeover para P-Slice 3.4.2
// (portada de TitleState.hx de DDTO). Clase nueva: no reemplaza al TitleState de P-Slice.
// Sin SaveData: todos los popups de doki estan disponibles.
class DokiTitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var menuBpm:Float = 120; // BPM de freakyMenu (120 = el de DDTO)
	var lastMenuBeat:Int = -1;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var textGroup:FlxGroup;

	var tbdSpr:FlxSprite;
	var doki:FlxSprite;
	var dokiApp:FlxSprite;
	var bottom:Int = 770;
	var top:Int = 270;

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var titleText:FlxSprite;
	var danceLeft:Bool = false;

	var curWacky:Array<String> = [];
	var isLeaving:Bool = false;
	var skippedIntro:Bool = false;

	override function create()
	{
		CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();

		persistentUpdate = true;
		FlxG.mouse.visible = true;

		curWacky = getIntroText();
		startIntro();

		super.create();
	}

	// ---- helpers: si falta un asset no crashea, usa un sprite transparente ----
	function loadImg(x:Float, y:Float, key:String):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(x, y);
		var g = Paths.image(key);
		if (g != null)
			s.loadGraphic(g);
		else
			s.makeGraphic(1, 1, 0x00000000);
		s.antialiasing = VsliceOptions.ANTIALIASING;
		return s;
	}

	function loadAtlas(x:Float, y:Float, key:String):FlxSprite
	{
		var s:FlxSprite = new FlxSprite(x, y);
		if (Paths.image(key) != null)
			s.frames = Paths.getSparrowAtlas(key);
		else
			s.makeGraphic(1, 1, 0x00000000);
		s.antialiasing = VsliceOptions.ANTIALIASING;
		return s;
	}

	function makeBackdrop(key:String, vx:Float, vy:Float):FlxBackdrop
	{
		var g = Paths.image(key);
		if (g == null)
			return null;
		var b:FlxBackdrop = new FlxBackdrop(g);
		b.velocity.set(vx, vy);
		b.antialiasing = VsliceOptions.ANTIALIASING;
		return b;
	}

	function startIntro()
	{
		if (!initialized)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(2, 0, 0.7);
		}

		var backdrop:FlxBackdrop = makeBackdrop('scrollingBG', -10, 0);
		if (backdrop != null) add(backdrop);

		var creditsBG:FlxBackdrop = makeBackdrop('credits/pocBackground', -50, 0);
		if (creditsBG != null) add(creditsBG);

		var scanline:FlxBackdrop = makeBackdrop('credits/scanlines', 0, 20);
		if (scanline != null) add(scanline);

		var gradient:FlxSprite = loadImg(0, 0, 'credits/gradent');
		gradient.scrollFactor.set(0.1, 0.1);
		gradient.screenCenter();
		gradient.setGraphicSize(Std.int(gradient.width * 1.4));
		add(gradient);

		logoBl = loadAtlas(-40, -12, 'Start_Screen_AssetsPlus');
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.8));
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.updateHitbox();

		gfDance = loadAtlas(FlxG.width * 0.4, FlxG.height * 0.07, 'gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		add(gfDance);
		add(logoBl);

		titleText = loadAtlas(170, FlxG.height * 0.8, 'titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		tbdSpr = loadImg(0, FlxG.height * .45, 'TBDLogo');
		tbdSpr.visible = false;
		tbdSpr.setGraphicSize(Std.int(tbdSpr.width * 0.9));
		tbdSpr.updateHitbox();
		tbdSpr.screenCenter(X);
		add(tbdSpr);

		// Popup de doki (todos disponibles, sin guardado): [nombre, y abajo, y arriba]
		var dokiArray:Array<Array<Dynamic>> = [
			['NatsukiPopup', 770, 270],
			['SayoriPopup', 770, 270],
			['YuriPopup', 770, 240],
			['MonikaPopup', 770, 180],
			['ProtagPopup', 770, 170]
		];
		var selected:Int = FlxG.random.int(0, dokiArray.length - 1);
		var dokiIndex:String = dokiArray[selected][0];
		bottom = dokiArray[selected][1];
		top = dokiArray[selected][2];

		dokiApp = loadAtlas(0, bottom, 'intro/' + dokiIndex);
		dokiApp.animation.addByPrefix('pop', dokiIndex, 26, false);
		dokiApp.screenCenter(X);
		add(dokiApp);

		doki = loadAtlas(50, 100, 'intro/DOKI DOKI');
		doki.animation.addByPrefix('doki', "Doki centered", 24, false);
		doki.alpha = 0.001;
		doki.updateHitbox();
		add(doki);

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroText():Array<String>
	{
		var fullText:String = Paths.getTextFromFile('data/introText.txt');
		var lines:Array<String> = [];
		if (fullText != null)
		{
			for (l in fullText.split('\n'))
				if (l.trim() != '')
					lines.push(l);
		}
		if (lines.length == 0)
			return ['Doki', 'Doki'];

		var parts:Array<String> = lines[FlxG.random.int(0, lines.length - 1)].split('--');
		if (parts.length < 2)
			parts.push('');
		return parts;
	}

	override function update(elapsed:Float)
	{
		menuBeatCheck();

		// Enter, clic o toque en pantalla
		var pressedEnter:Bool = controls.ACCEPT || FlxG.mouse.justPressed;

		if (pressedEnter && !isLeaving && skippedIntro)
		{
			if (VsliceOptions.FLASHBANG)
			{
				titleText.animation.play('press');
				FlxG.camera.flash(FlxColor.WHITE, 1);
			}
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			isLeaving = true;

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				MusicBeatState.switchState(new MainMenuState());
			});
		}

		if (pressedEnter && !skippedIntro && initialized)
			skipIntro();

		super.update(elapsed);
	}

	function menuBeatCheck()
	{
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			return;
		var crochet:Float = 60000 / menuBpm;
		var beat:Int = Math.floor(FlxG.sound.music.time / crochet);
		if (beat != lastMenuBeat)
		{
			// si hubo lag y se saltaron beats, se procesan los que faltaron
			var from:Int = (lastMenuBeat < 0) ? beat : lastMenuBeat + 1;
			if (beat - from > 4)
				from = beat;
			for (b in from...(beat + 1))
				menuBeatHit(b);
			lastMenuBeat = beat;
		}
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
			addText(textArray[i], (i * 60) + 200);
	}

	function addMoreText(text:String)
	{
		addText(text, (textGroup.length * 60) + 200);
	}

	function addText(text:String, y:Float)
	{
		var t:FlxText = new FlxText(0, y, FlxG.width, text, 48);
		t.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		credGroup.add(t);
		textGroup.add(t);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	function menuBeatHit(b:Int)
	{
		logoBl.animation.play('bump', true);
		danceLeft = !danceLeft;

		if (danceLeft)
			gfDance.animation.play('danceRight');
		else
			gfDance.animation.play('danceLeft');

		if (skippedIntro)
			return;

		switch (b)
		{
			case 1:
				createCoolText(['Team TBD']);
			case 3:
				tbdSpr.visible = true;
			case 4:
				tbdSpr.visible = false;
				deleteCoolText();
			case 5:
				createCoolText(['Powered', 'by']);
			case 7:
				addMoreText("Claude n' P-Slice");
			case 8:
				deleteCoolText();
			case 9:
				createCoolText([curWacky[0]]);
			case 11:
				addMoreText(curWacky[1]);
			case 12:
				deleteCoolText();
			case 13:
				dokiApp.animation.play('pop');
				FlxTween.tween(dokiApp, {"scale.x": 0.75, y: top}, 0.15, {
					ease: FlxEase.sineIn,
					startDelay: 0.2,
					onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(dokiApp, {"scale.x": 1}, 0.2, {ease: FlxEase.bounceInOut});
					}
				});
			case 14:
				doki.alpha = 1;
				doki.animation.play('doki');
			case 16:
				skipIntro();
		}
	}

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(tbdSpr);
			remove(doki);
			remove(dokiApp);

			if (VsliceOptions.FLASHBANG)
				FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
