#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

import protocol.PingPong;

class TcpTest extends haxe.unit.TestCase
{
	public function createRPCServer()
	{
		var port = Thread.readMessage(true);
		var server = new hxnet.tcp.Server(new hxnet.base.Factory(PingPong), port);
		while (Thread.readMessage(false) == null)
		{
			server.update();
		}
	}

	private var serverThread:Thread;
	private var serverPort:Int = 12000;

	public override function setup()
	{
		serverPort += 1;
		serverThread = Thread.create(createRPCServer);
		serverThread.sendMessage(serverPort);
	}

	public override function tearDown()
	{
		serverThread.sendMessage("finish");
	}

	private inline function updateClient(client:hxnet.tcp.Client, times:Int=100)
	{
		while (times-- > 0) client.update();
	}

	public function testRPC()
	{
		var client = new hxnet.tcp.Client();
		var rpc = new PingPong();
		client.protocol = rpc;
		client.connect(serverPort);
		rpc.call("ping");

		updateClient(client);

		assertTrue(rpc.pingCount > 0);
	}

	public function testRPCArguments()
	{
		var client = new hxnet.tcp.Client();
		var rpc = new PingPong();
		client.protocol = rpc;
		client.connect(serverPort);
		rpc.call("pong", [1, 12.4]);

		updateClient(client);

		assertTrue(rpc.pingCount > 0);
	}

	public function testRPCFailure()
	{
		var client = new hxnet.tcp.Client();
		var rpc = new PingPong();
		client.protocol = rpc;
		client.connect(serverPort);
		rpc.call("foo", [1, 20.4, "hi"]); // this call should fail

		updateClient(client, 1000);

		assertEquals(0, rpc.pingCount);
	}

	private var server:hxnet.interfaces.Server;
}
