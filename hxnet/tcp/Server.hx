package hxnet.tcp;

import sys.net.Host;
import sys.net.Socket;
import haxe.io.Bytes;
import haxe.io.BytesInput;

class Server
{

	public function new(protocol:Class<Protocol>, port:Int, hostname:String = "127.0.0.1")
	{
		protocolClass = protocol;

		bytes = Bytes.alloc(1024);

		listener = new Socket();
		listener.bind(new Host(hostname), port);
		listener.listen(1);
		listener.setBlocking(false);

		readSockets = [listener];
	}

	public function update()
	{
		var select = Socket.select(readSockets, null, null, 0);
		for (socket in select.read)
		{
			if (socket == listener)
			{
				var client = listener.accept();
				client.setBlocking(false);
				readSockets.push(client);

				var cnx = Type.createInstance(protocolClass, []);
				var connection = new Connection(client);
				client.custom = cnx;
				cnx.makeConnection(connection);
			}
			else
			{
				var cnx:Protocol = socket.custom;
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
					cnx.loseConnection("disconnected");
					socket.close();
					readSockets.remove(socket);
				}
				catch (e:haxe.io.Error)
				{
					// End of stream
				}

				// if we had data, send it to the protocol
				if (size > 0 && cnx != null)
				{
					cnx.dataReceived(new BytesInput(bytes, 0, size));
				}
			}
		}
	}

	private var protocolClass:Class<Protocol>;
	private var readSockets:Array<Socket>;
	private var listener:Socket;

	private var bytes:Bytes;

}
