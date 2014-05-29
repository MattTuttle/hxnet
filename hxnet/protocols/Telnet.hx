package hxnet.protocols;

import haxe.ds.IntMap;
import haxe.io.Input;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

/**
 * Telnet protocol
 */
class Telnet extends hxnet.base.Protocol
{

	/**
	 * Upon receiving data this method is called
	 * @param input The input to read from
	 */
	override public function dataReceived(input:Input)
	{
		var line = input.readLine();

		// strip out IAC codes
		var buffer = "";
		var i = 0, last = 0;
		while (i < line.length)
		{
			if (line.charCodeAt(i) == IAC)
			{
				buffer += line.substr(last, i - last);

				var command = line.charCodeAt(++i);
				if (command == 0xF1) { } // NOP
				else if (command == 0xFA) // SB
				{
					var code = line.charCodeAt(++i);
					var data = new BytesOutput();
					while (!(line.charCodeAt(i) == IAC && line.charCodeAt(i+1) == 0xF0)) // SE
					{
						data.writeByte(line.charCodeAt(++i));
					}
					handleIACData(code, data.getBytes());
					i += 1;
				}
				else
				{
					handleIAC(command, line.charCodeAt(++i));
				}
				last = i;
			}
			i += 1;
		}
		buffer += line.substr(last, i - last);

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

	public function iacWill(code:Int):Void { iacSend(WILL, code); }
	public function iacWont(code:Int):Void { iacSend(WONT, code); }

	private inline function iacSend(command:Int, code:Int):Void
	{
		var out = new BytesOutput();
		out.writeByte(IAC);
		out.writeByte(command);
		out.writeByte(code);
		cnx.writeBytes(out.getBytes());
	}

	public function handleIACData(code:Int, data:Bytes) { }
	private function handleIAC(command:Int, code:Int) { }

	/**
	 * Send a line of text over the connection
	 * @param data The string data to write
	 */
	public function writeLine(data:String):Void
	{
		cnx.writeBytes(Bytes.ofString(data + "\r\n"));
	}

	/**
	 * Turns echo on/off on the remote side. Useful for password entry.
	 * @param show Whether to show keyboard output on the remote connection.
	 */
	public function echo(show:Bool = true) { iacSend(show ? 0xFC : 0xFB, 0x01); }

	/**
	 * Prompt the user for feedback and return answer to callback
	 * @param prompt    The line of text to prompt user for input
	 * @param callback  The method to return the user's response
	 */
	public function prompt(prompt:String, callback:String->Bool)
	{
		promptBytes = Bytes.ofString(prompt + " ");
		promptCallback = callback;
		cnx.writeBytes(promptBytes);
	}

	private var promptBytes:Bytes;
	private var promptCallback:String->Bool;

	/**
	 * Overridable method when a line is received. Used in subclasses.
	 */
	private function lineReceived(line:String) { }

	private static inline var WILL = 0xFB;
	private static inline var WONT = 0xFC;
	private static inline var DO   = 0xFD;
	private static inline var DONT = 0xFE;
	private static inline var IAC  = 0xFF;

}
