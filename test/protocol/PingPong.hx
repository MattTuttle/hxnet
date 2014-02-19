package protocol;

import hxnet.protocols.RPC;

// super simple ping/pong protocol
class PingPong extends RPC
{
	public var pingCount:Int = 0;

	public function ping()
	{
		// endless loop...
		pingCount += 1;
		call("ping");
	}

	public function pong(a:Int, b:Float)
	{
		call("ping");
	}
}