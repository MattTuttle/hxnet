package hxnet.tcp;

import sys.net.Host;
import sys.net.Socket;
import haxe.io.Bytes;
import haxe.io.BytesInput;

class Client implements hxnet.interfaces.IClient
{

	public var protocol(default, set):Protocol;

	public function new()
	{
		client = new Socket();
		bytes = Bytes.alloc(1024);
	}

	public function connect(hostname:String = "127.0.0.1", port:Null<Int> = 12800)
	{
		try
		{
			#if flash
			client.connect(hostname, port);
			#else
			client.connect(new Host(hostname), port);
			client.setBlocking(false);
			#end
		}
		catch (e:Dynamic)
		{
			trace(e);
			client = null;
		}
	}

	public function update()
	{
		if (protocol == null || client == null) return;

		var select = Socket.select([client], null, null, 0);
		for (socket in select.read)
		{
			var size:Int = 0;

			try
			{
				for (i in 0...bytes.length)
				{
					size = i;
					bytes.set(size, socket.input.readByte());
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
				// End of stream
			}

			if (size > 0)
			{
				protocol.dataReceived(new BytesInput(bytes, 0, size));
			}
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
	private var bytes:Bytes;

}
