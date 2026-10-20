package objects;

import backend.animation.PsychAnimationController;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class StrumNote extends FlxSprite {
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;

	private var noteData:Int = 0;

	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;

	private var player:Int;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String {
		if (texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var rotationFallback:Bool = false;
	public var fallbackRotation:Float = 0;

	private static final arrowRotations:Array<Float> = [180, // Left
		90, // Down
		- 90, // Up
		0 // Right
	];

	public var useRGBShader:Bool = true;

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB)
			useRGBShader = false;

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
		if (PlayState.isPixelStage)
			arr = ClientPrefs.data.arrowRGBPixel[leData];

		if (leData <= arr.length) {
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if (PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1)
			skin = PlayState.SONG.arrowSkin;
		else
			skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$customSkin.png', IMAGE))
			skin = customSkin;

		texture = skin; // Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote() {
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		if (PlayState.isPixelStage) {
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4) {
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		} else {
			frames = Paths.getSparrowAtlas(texture);

			antialiasing = ClientPrefs.data.antialiasing;

			var colors:Array<String> = ['purple', // Left
				'blue', // Down
				'green', // Up
				'red' // Right
			];

			var staticPrefixes:Array<String> = ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT'];

			var pressPrefixes:Array<String> = ['left press', 'down press', 'up press', 'right press'];

			var confirmPrefixes:Array<String> = ['left confirm', 'down confirm', 'up confirm', 'right confirm'];

			var wanted:Int = Math.abs(noteData) % 4;
			var base:Int = wanted;

			// Find the requested direction first.
			var foundFrames = [];
			@:privateAccess
			animation.findByPrefix(foundFrames, staticPrefixes[wanted]);

			// If missing, find another available direction.
			if (foundFrames.length == 0) {
				for (i in 0...staticPrefixes.length) {
					var candidateFrames = [];

					@:privateAccess
					animation.findByPrefix(candidateFrames, staticPrefixes[i]);

					if (candidateFrames.length > 0) {
						base = i;
						break;
					}
				}
			}

			// Determine whether a fallback is needed.
			var baseFrames = [];
			@:privateAccess
			animation.findByPrefix(baseFrames, staticPrefixes[base]);

			rotationFallback = base != wanted && baseFrames.length > 0;
			fallbackRotation = rotationFallback ? arrowRotations[wanted] - arrowRotations[base] : 0;

			// Load the available arrow graphic for all three animations.
			animation.addByPrefix('static', staticPrefixes[base]);

			var pressFrames = [];
			@:privateAccess
			animation.findByPrefix(pressFrames, pressPrefixes[base]);

			if (pressFrames.length > 0)
				animation.addByPrefix('pressed', pressPrefixes[base], 24, false);
			else
				animation.addByPrefix('pressed', staticPrefixes[base]);

			var confirmFrames = [];
			@:privateAccess
			animation.findByPrefix(confirmFrames, confirmPrefixes[base]);

			if (confirmFrames.length > 0)
				animation.addByPrefix('confirm', confirmPrefixes[base], 24, false);
			else
				animation.addByPrefix('confirm', staticPrefixes[base]);

			// Preserve the original animation names used by other scripts.
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			setGraphicSize(Std.int(width * 0.7));
		}
		updateHitbox();

		if (lastAnim != null) {
			playAnim(lastAnim, true);
		}
	}

	public function playerPosition() {
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float) {
		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);

		// Reset rotation whenever the animation changes.
		angle = rotationFallback ? fallbackRotation : 0;

		if (animation.curAnim != null) {
			centerOffsets();
			centerOrigin();
		}

		if (useRGBShader)
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}
