package hxnet.udp;

import sys.net.UdpSocket;
import sys.net.Address;
import hxnet.interfaces.IProtocol;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.Timer;

typedef ClientConnection = {
	var timeout:Float;
	var protocol:IProtocol;
}

class Server implements hxnet.interfaces.IServer
{

	public function new(protocol:Class<IProtocol>, port:Int, hostname:String = "127.0.0.1")
	{
		connections = new Map<Address, ClientConnection>();
		buffer = Bytes.alloc(512);
		protocolClass = protocol;

		listener = new UdpSocket();
		listener.setBlocking(false);
		address = new Address();
		address.port = port;

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

		var bytesReceived = listener.readFrom(buffer, 0, buffer.length, address);
		trace(bytesReceived);
		if (bytesReceived > 0)
		{
			var input = new BytesInput(buffer, 0, bytesReceived);

			var peer = listener.peer();
			var remoteAddress = new Address(); // TODO: get from read socket
			remoteAddress.host = peer.host.ip;
			remoteAddress.port = peer.port;
			trace(peer);

			// var cnx:ClientConnection;
			// if (connections.exists(remoteAddress))
			// {
			// 	cnx = connections.get(remoteAddress);
			// }
			// else
			// {
			// 	// new connection
			// 	var protocol = Type.createInstance(protocolClass, []);
			// 	var client = new UdpSocket();
			// 	protocol.makeConnection(new Connection(client, remoteAddress));
			// 	cnx = { protocol: protocol, timeout: 10 };
			// 	connections.set(remoteAddress, cnx);
			// }
			// cnx.timeout = 10;
			// cnx.protocol.dataReceived(input);
		}
	}

	public function close()
	{
		listener.close();
	}

	private var lastUpdate:Float;
	private var listener:UdpSocket;
	private var address:Address;
	private var buffer:Bytes;
	private var protocolClass:Class<IProtocol>;
	private var connections:Map<Address, ClientConnection>;

}
