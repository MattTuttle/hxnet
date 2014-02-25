package hxnet.protocols;

import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

class Telnet extends hxnet.base.Protocol
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

		lineReceived(buffer);
	}

	public function writeLine(data:String)
	{
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

	private var promptBytes:Bytes;
	private var promptCallback:String->Bool;

	private function lineReceived(line:String) { }
}