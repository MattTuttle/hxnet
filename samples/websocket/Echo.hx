package websocket;

class Echo extends hxnet.protocols.WebSocket
{

	override private function recvText(text:String) {
		sendText(text);
	}

	override private function recvBinary(data:haxe.io.Bytes) {
		sendBinary(data);
	}

	static public function main()
	{
		var server = new hxnet.tcp.Server(new hxnet.base.Factory(Echo), 4000, "localhost");
		server.start();
	}

}
