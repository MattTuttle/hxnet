package hxnet.udp;

import sys.net.UdpSocket;
import sys.net.Address;
import sys.net.Host;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hxnet.interfaces.IProtocol;

class Client implements hxnet.interfaces.IClient
{
	public var protocol(default, set):IProtocol;

	public function new()
	{
		buffer = Bytes.alloc(512);
		client = new UdpSocket();
	}

	public function connect(?hostname:String, port:Null<Int> = 12800)
	{
		var host:Host = new Host(hostname == null ? Host.localhost() : hostname);
		address = new Address();
		address.host = host.ip;
		address.port = port;
	}

	public function update()
	{
		if (client != null)
		{
			var bytesReceived = client.readFrom(buffer, 0, buffer.length, address);
			if (bytesReceived > 0)
			{
				protocol.dataReceived(new BytesInput(buffer, 0, bytesReceived));
			}
		}
	}

	public function close()
	{
		client = null;
		protocol.loseConnection();
	}

	private function set_protocol(value:IProtocol):IProtocol
	{
		if (client != null)
			value.makeConnection(new Connection(client, address));
		protocol = value;
		return value;
	}

	private var client:UdpSocket;
	private var buffer:Bytes;
	// connection info
	private var address:Address;
	private var port:Int;
}
