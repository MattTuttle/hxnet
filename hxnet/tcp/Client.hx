package hxnet.tcp;


#if flash
import flash.net.Socket;
#else
import sys.net.Host;
import sys.net.Socket;
#end
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
		buffer = Bytes.alloc(8192);
	}

	public function connect(?hostname:String, port:Null<Int> = 12800)
	{
		try
		{
			client = new Socket();
#if flash
			client.connect(hostname, port);
#else
			if (hostname == null) hostname = Host.localhost();
			client.connect(new Host(hostname), port);
			client.setBlocking(blocking);
#end
			// prevent recreation of array on every update
			readSockets = [client];
			if (protocol != null)
			{
				protocol.makeConnection(new Connection(client));
			}
		}
		catch (e:Dynamic)
		{
			trace(e);
			client = null;
		}
	}

	public function update(timeout:Float=1)
	{
		if (!connected) return;

		try
		{
#if flash
			readSocket(client);
#else
			if (blocking)
			{
				protocol.dataReceived(client.input);
			}
			else
			{
				select(timeout);
			}
#end
		}
		catch (e:haxe.io.Eof)
		{
			protocol.loseConnection("disconnected");
			client.close();
			client = null;
		}
	}

	private function readSocket(socket:Socket)
	{
		var byte:Int = 0,
			bytesReceived:Int = 0,
			len = buffer.length;
		while (bytesReceived < len)
		{
			try
			{

				byte = #if flash socket.readByte() #else socket.input.readByte() #end;
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

#if !flash
	private inline function select(timeout:Float=1)
	{
		var select = Socket.select(readSockets, null, null, timeout);
		for (socket in select.read)
		{
			readSocket(socket);
		}
	}
#end

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
#if !flash
		if (client != null) client.setBlocking(value);
#end
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
