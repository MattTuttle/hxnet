package hxnet.protocols;

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

	/**
	 * Send a line of text over the connection
	 * @param data The string data to write
	 */
	public function writeLine(data:String)
	{
		data += "\r\n";
		cnx.writeBytes(Bytes.ofString(data));
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
}
