package hxnet.helpers;

enum EraseMode
{
	BeforeCursor;
	AfterCursor;
	Entire;
}

enum Color
{
	Black;
	Red;
	Green;
	Yellow;
	Blue;
	Magenta;
	Cyan;
	White;
}

enum Attribute
{
	Reset;        // normal
	Bold;
	Faint;        // not widely supported
	Italic;       // not widely supported
	Underline;
	Blink;
	BlinkRapid;   // not widely supported
	Negative;
	Conceal;      // not widely supported
	CrossedOut;   // not widely supported
}

class Terminal
{
	//
	// CURSOR POSITION
	//
	public static inline function cursorUp(n:Int = 1):String { return CSI + n + "A"; }
	public static inline function cursorDown(n:Int = 1):String { return CSI + n + "B"; }
	public static inline function cursorForward(n:Int = 1):String { return CSI + n + "C"; }
	public static inline function cursorBackward(n:Int = 1):String { return CSI + n + "D"; }
	public static inline function cursorNextLine(n:Int = 1):String { return CSI + n + "E"; }
	public static inline function cursorPrevLine(n:Int = 1):String { return CSI + n + "F"; }
	public static inline function cursorPosition(x:Int = 1, y:Int = 1):String
	{
		return CSI + x + ";" + y + "H"; // could also be "f" instead of "H"
	}
	public static inline function cursorSave():String { return CSI + "s"; }
	public static inline function cursorRestore():String { return CSI + "u"; }
	public static inline function cursorHide():String { return CSI + "?25l"; }
	public static inline function cursorShow():String { return CSI + "?25h"; }

	//
	// ERASE
	//
	private static inline function eraseMode(mode:EraseMode):Int
	{
		switch (mode)
		{
			case BeforeCursor: return 1;
			case Entire:       return 2;
			default:           return 0;
		}
	}
	public static inline function eraseDisplay(?mode:EraseMode):String
	{
		return CSI + eraseMode(mode) + "J";
	}
	public static inline function eraseInLine(?mode:EraseMode):String
	{
		return CSI + eraseMode(mode) + "K";
	}

	//
	// GRAPHICS MODE
	//
	public static function setText(?foreground:Color, ?background:Color, ?attribute:Attribute):String
	{
		var commands = new Array<String>();
		if (attribute == null && foreground == null && background == null)
		{
			commands.push("0"); // reset
		}
		else
		{
			if (attribute != null) commands.push(Std.string(Type.enumIndex(attribute)));
			if (foreground != null) commands.push("3" + Type.enumIndex(foreground));
			if (background != null) commands.push("4" + Type.enumIndex(background));
		}
		return CSI + commands.join(";") + "m";
	}

	private static inline var CSI:String = "\x1B[";
}
