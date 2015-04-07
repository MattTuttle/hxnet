import hxnet.interfaces.Connection;
import hxnet.protocols.Telnet;
import hxnet.tcp.Client;


/**
 * ...
 * @author Samuel Weeks
 */

class ClientSide extends hxnet.protocols.Telnet
{

	
	static public function main()
	{
		var client = new hxnet.tcp.Client();
		client.protocol = new ClientSide();
		client.connect("192.168.0.102", 10000);
		client.blocking = false; // important for gui clients

		while (true)
		{
			// application logic
			client.update();
		}
	}
	
	override private function lineReceived(line:String)
	{
		trace("line received from server = " + line);
		if (line == "personal message")
		{
			this.personalMessage();
		}
	}
	private function personalMessage():Void
	{
		trace("got a personal message from the server");
	}
	
	override public function onConnect(cnx:Connection) 
	{
		super.onConnect(cnx);
		trace("connected to Server");
		writeLine("connection confirmed");
		
	
		
	}

}
