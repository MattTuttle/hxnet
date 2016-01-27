import hxnet.interfaces.Connection;
import hxnet.protocols.Telnet;
import hxnet.tcp.Server;
import hxnet.base.Factory;
import haxe.io.Bytes;



/**
 * ...
 * @author Samuel Weeks
 */

class ServerSide extends Telnet
{
	static public var clientGroup:Array<Connection> = new Array();
	
	static public function main()
	{
		var server = new hxnet.tcp.Server(new hxnet.base.Factory(ServerSide), 10000, "192.168.0.102");
		server.start();
	}
	
	override public function onConnect(cnx) 
	{
		trace("a client has connected");
		super.onConnect(cnx);
	}
	
	override public function onAccept(cnx, server) 
	{
		trace("accpted a client connect");
		super.onAccept(cnx, server);
		this.addClientToClientGroup(this.cnx);
		
		
	}
	
	override function lineReceived(line:String) 
	{
		trace("line received from client = " + line);
		super.lineReceived(line);
		
		//send private message to a given client connection make sure client is not null to avoid an error
		//client 1
		if (ServerSide.clientGroup[0] != null)
		{
		ServerSide.clientGroup[0].writeBytes(Bytes.ofString("personal messagee"));
		}
		
		//client 2
		if (ServerSide.clientGroup[1] != null)
		{
		ServerSide.clientGroup[1].writeBytes(Bytes.ofString("personal messagee"));
		}
		
		
		
	}
	
	override public function writeLine(data:String):Void 
	{
		trace("wrting a line to client");
		super.writeLine(data);
	}
	
	private function addClientToClientGroup(cnxObject:Connection):Void
	{
		ServerSide.clientGroup.push(cnx);
		
	}

}
