package hxnet.protocols;

import haxe.io.Input;

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

	private function lineReceived(line:String) { }
}