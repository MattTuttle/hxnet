import hxnet.tcp.Server;

class Echo extends hxnet.protocols.WebSocket
{
	override private function recvText(text:String) {
		sendText(text);
	}

	override private function recvBinary(data:haxe.io.Bytes) {
		sendBinary(data);
	}
}

class Main
{

	public function new()
	{
		server = new Server(new hxnet.base.Factory(Echo), 4000, "localhost");
		server.listen();
		while (true)
		{
			server.update();
		}
	}

	static public function main()
	{
		new Main();
	}

	private var server:Server;
}