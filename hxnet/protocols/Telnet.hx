package hxnet.protocols;

import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

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
		// filter out IAC commands for now
		if (buffer.charCodeAt(0) == 0xFF)
			return;

		if (promptCallback != null)
		{
			// save current callback for comparison
			var callback = promptCallback;
			if (callback(buffer))
			{
				// don't set to null if a different prompt has been set
				if (promptCallback == callback)
					promptCallback = null;
			}
			else
			{
				cnx.writeBytes(promptBytes);
			}
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
		data += "\r\n";
		cnx.writeBytes(Bytes.ofString(data));
	}

	public function echo(show:Bool = true)
	{
		var out = new BytesOutput();
		out.writeByte(0xFF);
		out.writeByte(show ? 0xFC : 0xFB);
		out.writeByte(0x01);
		if (show)
			out.writeString("\r\n");
		cnx.writeBytes(out.getBytes());
	}

	public function prompt(prompt:String, callback:String->Bool)
	{
		promptBytes = Bytes.ofString(prompt + " ");
		promptCallback = callback;
		cnx.writeBytes(promptBytes);
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

	private var promptBytes:Bytes;
	private var promptCallback:String->Bool;

	private function lineReceived(line:String) { }
}