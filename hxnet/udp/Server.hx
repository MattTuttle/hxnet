package hxnet.udp;

import hxnet.udp.Socket;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;

class Server
{

	public function new(protocol:Class<Protocol>, port:Int, hostname:String = "127.0.0.1")
	{
		connections = new StringMap<Protocol>();
		buffer = Bytes.alloc(512);
		protocolClass = protocol;

		listener = new Socket();
		listener.create();
		listener.bind(port);
		listener.nonBlocking = true;
	}

	public function update()
	{
		var bytesReceived = listener.receive(buffer);
		if (bytesReceived > 0)
		{
			var input = new BytesInput(buffer, 0, bytesReceived);
			var remote = listener.remoteAddress;
			var cnx:Protocol;
			if (connections.exists(remote.address))
			{
				cnx = connections.get(remote.address);
			}
			else
			{
				cnx = Type.createInstance(protocolClass, []);
				var client = new Socket();
				client.connect(remote.address, remote.port);
				cnx.makeConnection(new Connection(client));
				connections.set(remote.address, cnx);
			}
			cnx.dataReceived(input);
		}
	}

	private var listener:Socket;
	private var buffer:Bytes;
	private var protocolClass:Class<Protocol>;
	private var connections:StringMap<Protocol>;

}
