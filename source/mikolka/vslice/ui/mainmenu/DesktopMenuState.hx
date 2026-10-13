package mikolka.vslice.ui.mainmenu;

import mikolka.vslice.freeplay.FreeplayState;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import mikolka.vslice.ui.title.TitleState;
#if !LEGACY_PSYCH
import states.CreditsState;
#end
import mikolka.compatibility.VsliceOptions;

// Menu principal personalizado (portado de Codename Engine).
// Reemplaza source/mikolka/vslice/ui/mainmenu/DesktopMenuState.hx
@:access(mikolka.vslice.ui.MainMenuState)
class DesktopMenuState extends FlxBasic
{
	var optionShit:Array<String> = ['freeplay', 'options', 'credits'];

	public static var curSelected:Int = 0;

	var selectedSomethin:Bool = false;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var camFollow:FlxObject;
	var host:MainMenuState;

	var logo:FlxSprite;
	var bailecito:FlxSprite;
	var baseBgScale:Float = 1;
	var bgBumpTween:FlxTween;
	var logoSide:Int = 0;
	var lastBeat:Int = -1;
	var bpm:Float = 102; // BPM de freakyMenu

	public function new(host:MainMenuState)
	{
		super();
		this.host = host;
		host.add(this);

		host.bg.scrollFactor.set(0.5, 0.5);
		host.bg.updateHitbox();
		host.bg.screenCenter();
		baseBgScale = host.bg.scale.x;

		host.magenta.scrollFactor.set(0.5, 0.5);
		host.magenta.updateHitbox();
		host.magenta.screenCenter();

		logo = new FlxSprite(10, -35).loadGraphic(Paths.image('menus/logo'));
		logo.scale.set(0.25, 0.25);
		logo.updateHitbox();
		logo.antialiasing = VsliceOptions.ANTIALIASING;
		host.add(logo);

		camFollow = new FlxObject(FlxG.width / 2, FlxG.height / 2, 1, 1);
		host.add(camFollow);

		menuItems = new FlxTypedGroup<FlxSprite>();
		host.add(menuItems);

		for (i in 0...optionShit.length)
		{
			var option:String = optionShit[i];
			var menuItem:FlxSprite = new FlxSprite(0, (i * 100) + 350);
			menuItem.antialiasing = VsliceOptions.ANTIALIASING;
			menuItem.frames = Paths.getSparrowAtlas('menus/mainmenu/' + option);
			menuItem.animation.addByPrefix('idle', option + " idle", 24);
			menuItem.animation.addByPrefix('selected', option + " selected", 24);
			menuItem.animation.play('idle');
			menuItem.scale.set(0.6, 0.6);
			menuItem.updateHitbox();
			menuItem.x = -menuItem.width; // empieza fuera de pantalla
			menuItem.ID = i;
			menuItems.add(menuItem);

			FlxTween.tween(menuItem, {x: 0}, 0.3, {startDelay: 0.3 + i * 0.1});
		}

		var gyatt:Bool = FlxG.random.bool(10);
		bailecito = new FlxSprite();
		bailecito.frames = Paths.getSparrowAtlas(gyatt ? 'menus/kingyatt' : 'menus/miniking');
		bailecito.animation.addByPrefix('baile', gyatt ? 'kingyatt' : 'baile', 24, true);
		bailecito.animation.play('baile');
		if (gyatt)
		{
			bailecito.scale.set(2, 2);
			bailecito.updateHitbox();
		}
		bailecito.scrollFactor.set();
		bailecito.x = FlxG.width - bailecito.width;
		bailecito.y = FlxG.height - bailecito.height - 20;
		host.add(bailecito);

		FlxG.camera.follow(camFollow, null, 0.06);
		changeItem();

		#if TOUCH_CONTROLS_ALLOWED
		host.addTouchPad('UP_DOWN', 'A_B');
		#end
	}

	override function update(elapsed:Float)
	{
		updateBeat();

		if (!selectedSomethin)
		{
			if (host.controls.UI_UP_P)
				changeItem(-1);

			if (host.controls.UI_DOWN_P)
				changeItem(1);

			if (host.controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			// Mouse / toque
			var clicked:Bool = false;
			if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0 || FlxG.mouse.justPressed)
			{
				var over:Int = -1;
				for (i in 0...menuItems.members.length)
				{
					var m:FlxSprite = menuItems.members[i];
					if (m != null && m.alive && FlxG.mouse.overlaps(m))
					{
						over = i;
						break;
					}
				}
				if (over != -1)
				{
					if (over != curSelected)
						changeItem(0, over);
					clicked = FlxG.mouse.justPressed;
				}
			}

			if (host.controls.ACCEPT || clicked)
				selectItem();
		}

		super.update(elapsed);
	}

	function selectItem()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		selectedSomethin = true;

		if (VsliceOptions.FLASHBANG)
			FlxFlicker.flicker(host.magenta, 1.1, 0.15, false);

		FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
		{
			switch (optionShit[curSelected])
			{
				case 'freeplay':
					{
						host.persistentDraw = true;
						host.persistentUpdate = false;
						// Freeplay tiene su propia transicion
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						host.openSubState(new FreeplayState());
						host.subStateOpened.addOnce(state ->
						{
							for (i in 0...menuItems.members.length)
							{
								menuItems.members[i].revive();
								menuItems.members[i].alpha = 1;
								menuItems.members[i].visible = true;
							}
							selectedSomethin = false;
							changeItem(0);
						});
					}
				case 'credits':
					MusicBeatState.switchState(new CreditsState());
				case 'options':
					host.goToOptions();
			}
		});

		for (i in 0...menuItems.members.length)
		{
			if (i == curSelected)
				continue;
			FlxTween.tween(menuItems.members[i], {alpha: 0, x: -50}, 0.4, {
				ease: FlxEase.quadOut,
				onComplete: function(twn:FlxTween)
				{
					menuItems.members[i].kill();
				}
			});
		}
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
			onBeat(beat, crochet);
		}
	}

	function onBeat(beat:Int, crochet:Float)
	{
		if (bgBumpTween != null)
			bgBumpTween.cancel();
		host.bg.scale.set(baseBgScale + 0.01, baseBgScale + 0.01);
		bgBumpTween = FlxTween.tween(host.bg.scale, {x: baseBgScale, y: baseBgScale}, crochet / 1000, {ease: FlxEase.circOut});

		if (beat % 2 == 0)
		{
			logoSide++;
			FlxTween.tween(logo, {angle: (logoSide % 2 == 0) ? -2 : 2}, (crochet / 1000) * 1.9, {ease: FlxEase.sineOut});
		}
	}

	function changeItem(huh:Int = 0, target:Int = -1)
	{
		if (huh != 0 || (target != -1 && target != curSelected))
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);

		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();

		curSelected = (target != -1) ? target : curSelected + huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();

		camFollow.setPosition(FlxG.width / 2, (menuItems.members[curSelected].getGraphicMidpoint().y * 0.1) + 300);
	}
}
