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

	public function new()
	{
		super();
		iacSupport = new IntMap<Bool>();
	}

	/**
	 * Upon receiving data this method is called
	 * @param input The input to read from
	 */
	override public function dataReceived(input:Input)
	{
		var buffer = input.readLine();

		// handle IAC codes
		while (buffer.charCodeAt(0) == IAC)
		{
			iacSupport.set(buffer.charCodeAt(2), (buffer.charCodeAt(1) == DO) ? true : false);
			buffer = buffer.substr(3);
		}

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

	public inline function iacSupports(code:Int):Bool
	{
		return iacSupport.exists(code) ? iacSupport.get(code) : false;
	}

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

	private var iacSupport:IntMap<Bool>;

	private static inline var WILL = 251;
	private static inline var WONT = 252;
	private static inline var DO   = 253;
	private static inline var DONT = 254;
	private static inline var IAC  = 255;

}
