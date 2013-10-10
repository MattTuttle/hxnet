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
		if (buffer == "exit")
		{
			cnx.close();
		}
		lineReceived(buffer);
	}

	public function writeLine(data:String)
	{
		cnx.writeBytes(Bytes.ofString(data + "\n"));
	}

	public function setText(?foreground:Color, ?background:Color, ?attribute:Attribute):String
	{
		if (attribute == null) attribute = Reset;
		var color = "\x1b[" + Type.enumIndex(attribute);
		if (foreground != null) color += ";3" + Type.enumIndex(foreground);
		if (background != null) color += ";4" + Type.enumIndex(background);
		return  color + "m";
	}

	private function lineReceived(line:String) { }
}