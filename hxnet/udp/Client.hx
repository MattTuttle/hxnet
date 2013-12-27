package hxnet.udp;

import hxnet.udp.Socket;
import haxe.io.Bytes;
import haxe.io.BytesInput;

class Client implements hxnet.interfaces.IClient
{
	public var protocol(default, set):Protocol;

	public function new()
	{
		buffer = Bytes.alloc(512);
		client = new Socket();
	}

	public function connect(hostname:String = "127.0.0.1", port:Null<Int> = 12800)
	{
		client.connect(hostname, port);
		client.nonBlocking = true;
		this.host = hostname;
		this.port = port;
	}

	public function update()
	{
		var bytesReceived = client.receive(buffer);
		if (bytesReceived > 0)
		{
			protocol.dataReceived(new BytesInput(buffer, 0, bytesReceived));
			trace("byte");
		}
	}

	public function close()
	{
		client.close();
		protocol.loseConnection();
	}

	private function set_protocol(value:Protocol):Protocol
	{
		if (client != null)
			value.makeConnection(new Connection(client));
		protocol = value;
		return value;
	}

	private var client:Socket;
	private var buffer:Bytes;
	// connection info
	private var host:String;
	private var port:Int;
}
