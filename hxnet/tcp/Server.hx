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

	public function update(?timeout:Float=null)
	{
		var len = buffer.length,
			bytesReceived:Int,
			cnx:Protocol;
		var select = Socket.select(readSockets, null, null, timeout);
		for (socket in select.read)
		{
			if (socket == listener)
			{
				var client = listener.accept();
				client.setBlocking(false);
				readSockets.push(client);

				cnx = factory.buildProtocol();
				var connection = new Connection(client);
				client.custom = cnx;
				cnx.makeConnection(connection, false);
			}
			else
			{
				cnx = socket.custom;
				try
				{
					bytesReceived = socket.input.readBytes(buffer, 0, len);
					// check that buffer was filled
					if (bytesReceived > 0)
					{
						cnx.dataReceived(new BytesInput(buffer, 0, bytesReceived));
					}
				}
				catch (e:haxe.io.Eof)
				{
					cnx.loseConnection("disconnected");
					socket.close();
					readSockets.remove(socket);
				}
				if (!cnx.isConnected())
				{
					readSockets.remove(socket);
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

#end
