package telnet;

class Echo extends hxnet.protocols.Telnet
{

	override private function lineReceived(line:String)
	{
		writeLine(line);
	}

	static public function main()
	{
		var server = new hxnet.tcp.Server(new hxnet.base.Factory(Echo), 4000, "localhost");
		server.start();
	}

}
