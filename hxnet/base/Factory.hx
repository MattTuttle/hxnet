package hxnet.base;

import hxnet.interfaces.Protocol;

class Factory implements hxnet.interfaces.Factory
{
	public function new(protocol:Class<Protocol>)
	{
		this.protocol = protocol;
	}

	public function buildProtocol():Protocol
	{
		return Type.createInstance(protocol, []);
	}

	private var protocol:Class<Protocol>;
}
