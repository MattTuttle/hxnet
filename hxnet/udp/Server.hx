package hxnet.udp;

import sys.net.UdpSocket;
import sys.net.Address;
import sys.net.Host;
import hxnet.interfaces.Protocol;
import hxnet.interfaces.Factory;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.Timer;

typedef ClientConnection = {
	var timeout:Float;
	var protocol:Protocol;
}

class Server implements hxnet.interfaces.Server
{

	public function new(factory:Factory, port:Int, ?hostname:String)
	{
		connections = new Map<Address, ClientConnection>();
		buffer = Bytes.alloc(8192);
		this.factory = factory;

		var host = new Host(hostname == null ? Host.localhost() : hostname);

		listener = new UdpSocket();
		listener.bind(host, port);
		listener.setBlocking(false);

		// stores last remote address
		address = new Address();

		lastUpdate = Timer.stamp();
	}

	public function update(timeout:Float=1)
	{
		var now = Timer.stamp();
		var delta = now - lastUpdate;
		lastUpdate = now;

		for (cnx in connections)
		{
			cnx.timeout -= delta;
			if (cnx.timeout < 0)
			{
				cnx.protocol.loseConnection("timeout");
			}
		}

		try
		{
			var bytesReceived = listener.readFrom(buffer, 0, buffer.length, address);
			if (bytesReceived > 0)
			{
				var input = new BytesInput(buffer, 0, bytesReceived);

				var cnx:ClientConnection;
				if (connections.exists(address))
				{
					cnx = connections.get(address);
				}
				else
				{
					// new connection
					var protocol = factory.buildProtocol();
					var client = new UdpSocket();
					protocol.makeConnection(new Connection(client, address));
					cnx = { protocol: protocol, timeout: 10 };
					connections.set(address, cnx);
				}
				cnx.timeout = 10;
				cnx.protocol.dataReceived(input);
			}
		}
		catch (e:haxe.io.Error)
		{
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
	private var factory:Factory;
	private var connections:Map<Address, ClientConnection>;

}
