package hxnet.tcp;

import sys.net.Host;
import sys.net.Socket;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hxnet.interfaces.Protocol;

class Client implements hxnet.interfaces.Client
{

	public var protocol(default, set):Protocol;
	public var blocking(default, set):Bool = true;
	public var connected(get, never):Bool;

	public function new()
	{
		buffer = Bytes.alloc(1024);
	}

	public function connect(?hostname:String, port:Null<Int> = 12800)
	{
		try
		{
			client = new Socket();
			if (hostname == null) hostname = Host.localhost();
			client.connect(#if flash hostname #else new Host(hostname) #end, port);
			// prevent recreation of array on every update
			readSockets = [client];
			if (protocol != null)
			{
				protocol.makeConnection(new Connection(client));
			}
			client.setBlocking(blocking);
		}
		catch (e:Dynamic)
		{
			trace(e);
			client = null;
		}
	}

	public function update()
	{
		if (!connected) return;

		try
		{
			if (blocking)
			{
				protocol.dataReceived(client.input);
			}
			else
			{
				select();
			}
		}
		catch (e:haxe.io.Eof)
		{
			protocol.loseConnection("disconnected");
			client.close();
			client = null;
		}
	}

	private inline function select()
	{
		var select = Socket.select(readSockets, null, null, 0);
		var byte:Int = 0,
			len = buffer.length,
			bytesReceived:Int;
		for (socket in select.read)
		{
			bytesReceived = 0;
			while (bytesReceived < len)
			{
				try
				{
					byte = socket.input.readByte();
				}
				catch (e:haxe.io.Error)
				{
					// end of stream
					if (e == Blocked)
					{
						buffer.set(bytesReceived, byte);
						break;
					}
				}

				buffer.set(bytesReceived, byte);
				bytesReceived += 1;
			}

			// check that buffer was filled
			if (bytesReceived > 0)
			{
				protocol.dataReceived(new BytesInput(buffer, 0, bytesReceived));
			}
		}
	}

	public function close()
	{
		client.close();
		protocol.loseConnection();
		protocol = null;
		client = null;
	}

	private inline function get_connected():Bool
	{
		return client != null && protocol != null;
	}

	private function set_blocking(value:Bool):Bool
	{
		if (blocking == value) return value;
		if (client != null) client.setBlocking(value);
		return blocking = value;
	}

	private function set_protocol(value:Protocol):Protocol
	{
		if (client != null)
		{
			value.makeConnection(new Connection(client));
		}
		return protocol = value;
	}

	private var client:Socket;
	private var readSockets:Array<Socket>;
	private var buffer:Bytes;

}
