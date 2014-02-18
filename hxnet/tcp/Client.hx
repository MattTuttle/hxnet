package hxnet.tcp;

import sys.net.Host;
import sys.net.Socket;
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
		bytes = Bytes.alloc(1024);
	}

	public function connect(?hostname:String, port:Null<Int> = 12800)
	{
		try
		{
			client = new Socket();
			if (hostname == null) hostname = Host.localhost();
			#if flash
			client.connect(hostname, port);
			#else
			client.connect(new Host(hostname), port);
			#end
			if (protocol != null)
			{
				protocol.makeConnection(new Connection(client));
				client.setBlocking(protocol.isBlocking());
			}
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

		if (blocking)
		{
			try
			{
				protocol.dataReceived(client.input);
			}
			catch (e:haxe.io.Eof)
			{
				protocol.loseConnection("disconnected");
				client.close();
				client = null;
			}
		}
		else
		{
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
		return client != null;
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

	private var client:Socket;
	private var bytes:Bytes;

}
