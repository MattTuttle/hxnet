package hxnet.protocols;

import haxe.io.Input;
import haxe.io.Bytes;

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

class Telnet extends BaseProtocol
{
	public override function dataReceived(input:Input)
	{
		var buffer = input.readLine();

		if (promptCallback != null)
		{
			promptCallback(buffer);
			promptCallback = null;
			return;
		}

		if (buffer == "exit")
		{
			cnx.close();
		}
		lineReceived(buffer);
	}

	public function writeLine(data:String, reset:Bool=false)
	{
		if (reset) data += text(Reset); // reset to normal text
		data += "\n";
		cnx.writeBytes(Bytes.ofString(data));
	}

	public function prompt(prompt:String, callback:String->Void)
	{
		cnx.writeBytes(Bytes.ofString(prompt + " "));
		promptCallback = callback;
	}

	public function text(?foreground:Color, ?background:Color, ?attribute:Attribute):String
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
		return  "\x1b[" + commands.join(";") + "m";
	}

	private var promptCallback:String->Void;
	private function lineReceived(line:String) { }
}