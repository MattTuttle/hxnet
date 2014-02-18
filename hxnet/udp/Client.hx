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
	public var blocking(default, null):Bool = false;
	public var connected(get, never):Bool;

	public function new()
	{
		buffer = Bytes.alloc(1024);
		client = new UdpSocket();
	}

	public function connect(?hostname:String, port:Null<Int> = 12800)
	{
		var host:Host = new Host(hostname == null ? Host.localhost() : hostname);
		address = new Address();
		address.host = host.ip;
		address.port = port;
		connection = new Connection(client, address);
		protocol.makeConnection(connection);
	}

	public function update()
	{
		if (client == null) return;

		try
		{
			var bytesReceived = client.readFrom(buffer, 0, buffer.length, address);
			if (bytesReceived > 0)
			{
				protocol.dataReceived(new BytesInput(buffer, 0, bytesReceived));
			}
		}
		catch (e:haxe.io.Eof)
		{
			protocol.loseConnection("disconnected");
			client.close();
			client = null;
		}
		catch (e:haxe.io.Error)
		{
		}
	}

	public function close()
	{
		client = null;
		connection = null;
		protocol.loseConnection();
	}

	private function set_protocol(value:IProtocol):IProtocol
	{
		blocking = value.isBlocking();
		if (client != null)
		{
			value.makeConnection(new Connection(client));
			client.setBlocking(blocking);
		}
		protocol = value;
		return value;
	}

	private var connection:Connection;
	private var client:UdpSocket;
	private var buffer:Bytes;
	// connection info
	private var address:Address;
	private var port:Int;
}
