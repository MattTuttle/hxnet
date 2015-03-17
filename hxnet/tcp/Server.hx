package hxnet.tcp;

#if !flash

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
		buffer = Bytes.alloc(8192);

		if (hostname == null) hostname = Host.localhost();

		this.factory = factory;
		this.host = hostname;
		this.port = port;

		listener = new Socket();

		readSockets = [listener];
		clients = new Map<Socket, Connection>();
	}

	public function listen()
	{
		listener.bind(#if flash host #else new Host(host) #end, port);
		listener.listen(1);
		listener.setBlocking(blocking);
	}

	public function start()
	{
		listen();
		while (true) {
			update();
			Sys.sleep(0.01); // wait for 1 ms
		}
	}

	public function update(timeout:Float=1):Void
	{
		var protocol:Protocol;
		var bytesReceived:Int;
		var select = Socket.select(readSockets, null, null, timeout);
		for (socket in select.read)
		{
			if (socket == listener)
			{
				var client = listener.accept();
				var connection = new Connection(client);

				readSockets.push(client);
				clients.set(client, connection);

				client.setBlocking(false);
				client.custom = protocol = factory.buildProtocol();
				protocol.onAccept(connection, this);
			}
			else
			{
				protocol = socket.custom;
				try
				{
					bytesReceived = socket.input.readBytes(buffer, 0, buffer.length);
					// check that buffer was filled
					if (bytesReceived > 0)
					{
						protocol.dataReceived(new BytesInput(buffer, 0, bytesReceived));
					}
				}
				catch (e:haxe.io.Eof)
				{
					protocol.loseConnection("disconnected");
					socket.close();
					readSockets.remove(socket);
					clients.remove(socket);
				}
				if (!protocol.isConnected())
				{
					readSockets.remove(socket);
					clients.remove(socket);
				}
			}
		}
	}

	public function broadcast(bytes:Bytes):Bool
	{
		var success = true;
		for (client in clients)
		{
			if (!client.writeBytes(bytes))
			{
				success = false;
			}
		}
		return success;
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
	private var clients:Map<Socket, Connection>;
	private var listener:Socket;

	private var buffer:Bytes;

}

#end
