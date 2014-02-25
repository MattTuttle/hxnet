package hxnet.tcp;

import sys.net.Host;
import sys.net.Socket;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hxnet.interfaces.Factory;
import hxnet.interfaces.Protocol;

class Server implements hxnet.interfaces.Server
{

	public var host(default, null):String;
	public var port(default, null):Int;
	public var blocking(default, set):Bool = true;

	public function new(factory:Factory, port:Int, ?hostname:String)
	{
		buffer = Bytes.alloc(1024);

		this.factory = factory;
		this.host = (hostname == null ? Host.localhost() : hostname);
		this.port = port;

		listener = new Socket();
		listener.bind(new Host(host), port);
		listener.listen(1);
		listener.setBlocking(blocking);

		readSockets = [listener];
	}

	public function update()
	{
		var select = Socket.select(readSockets, null, null, 0);
		var byte:Int = 0,
			len = buffer.length,
			bytesReceived:Int;
		for (socket in select.read)
		{
			if (socket == listener)
			{
				var client = listener.accept();
				client.setBlocking(false);
				readSockets.push(client);

				var cnx = factory.buildProtocol();
				var connection = new Connection(client);
				client.custom = cnx;
				cnx.makeConnection(connection);
			}
			else
			{
				var protocol:Protocol = socket.custom;
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
	}

	public function close()
	{
		listener.close();
	}

	private function set_blocking(value:Bool):Bool
	{
		if (blocking == value) return value;
		if (listener != null) listener.setBlocking(value);
		return blocking = value;
	}

	private var factory:Factory;
	private var readSockets:Array<Socket>;
	private var listener:Socket;

	private var buffer:Bytes;

}
