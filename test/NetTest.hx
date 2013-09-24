#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

class MyProtocol extends hxnet.protocols.RPC
{
	public var pingCount:Int = 0;

	public function ping()
	{
		// endless loop...
		pingCount += 1;
		call("ping");
		trace(pingCount);
	}

	public function pong(a:Int, b:Float)
	{
		call("ping");
	}
}

class NetTest extends haxe.unit.TestCase
{
	public function createRPCServer()
	{
		var port = Thread.readMessage(true);
		var server = new hxnet.udp.Server(MyProtocol, port);
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

	private inline function updateClient(client:hxnet.udp.Client)
	{
		// update the client for a bit
		var i = 100;
		while (i-- > 0) client.update();
	}

	public function testRPC()
	{
		var client = new hxnet.udp.Client();
		var rpc = new MyProtocol();
		client.protocol = rpc;
		client.connect(serverPort);
		rpc.call("ping");

		updateClient(client);

		assertTrue(rpc.pingCount > 0);
	}

	public function testRPCArguments()
	{
		var client = new hxnet.udp.Client();
		var rpc = new MyProtocol();
		client.protocol = rpc;
		client.connect(serverPort);
		rpc.call("pong", [1, 12.4]);

		updateClient(client);

		assertTrue(rpc.pingCount > 0);
	}

	public function testRPCFailure()
	{
		var client = new hxnet.udp.Client();
		var rpc = new MyProtocol();
		client.protocol = rpc;
		client.connect(serverPort);
		rpc.call("ping", [1, 20.4, "hi"]); // this call should fail

		updateClient(client);

		assertEquals(0, rpc.pingCount);
	}

	public static function main()
	{
		var runner = new haxe.unit.TestRunner();
		runner.add(new NetTest());
		runner.run();
	}

	private var server:hxnet.udp.Server;
}
