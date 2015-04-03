package telnet;

class Client extends hxnet.protocols.Telnet
{

	override private function lineReceived(line:String)
	{
		trace(line);
	}

	static public function main()
	{
		var client = new hxnet.tcp.Client();
		client.protocol = new Client();
		client.connect("localhost", 4000);

		while (true)
		{
			// application logic
			client.update();
		}
	}

}
