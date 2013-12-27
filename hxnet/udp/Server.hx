package hxnet.udp;

import hxnet.udp.Socket;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.Timer;

typedef ClientConnection = {
	var timeout:Float;
	var protocol:Protocol;
}

class Server implements hxnet.interfaces.IServer
{

	public function new(protocol:Class<Protocol>, port:Int, hostname:String = "127.0.0.1")
	{
		connections = new Map<RemoteAddress, ClientConnection>();
		buffer = Bytes.alloc(512);
		protocolClass = protocol;

		listener = new Socket();
		listener.bind(port);
		listener.nonBlocking = true;

		lastUpdate = Timer.stamp();
	}

	public function update()
	{
		var now = Timer.stamp();
		var delta = now - lastUpdate;
		lastUpdate = now;

		for (cnx in connections)
		{
			cnx.timeout -= delta;
			trace(cnx.timeout);
			if (cnx.timeout < 0)
			{
				cnx.protocol.loseConnection("timeout");
			}
		}

		var bytesReceived = listener.receive(buffer);
		trace(bytesReceived);
		if (bytesReceived > 0)
		{
			var input = new BytesInput(buffer, 0, bytesReceived);
			var remote = listener.remoteAddress;
			var cnx:ClientConnection;
			if (connections.exists(remote))
			{
				cnx = connections.get(remote);
			}
			else
			{
				// new connection
				var protocol = Type.createInstance(protocolClass, []);
				var client = new Socket();
				client.connect(remote.address, remote.port);
				protocol.makeConnection(new Connection(client));
				cnx = { protocol: protocol, timeout: 10 };
				connections.set(remote, cnx);
			}
			cnx.timeout = 10;
			cnx.protocol.dataReceived(input);
		}
	}

	public function close()
	{
		listener.close();
	}

	private var lastUpdate:Float;
	private var listener:Socket;
	private var buffer:Bytes;
	private var protocolClass:Class<Protocol>;
	private var connections:Map<RemoteAddress, ClientConnection>;

}
