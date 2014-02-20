package hxnet.base;

import hxnet.interfaces.IFactory;
import hxnet.interfaces.IProtocol;

class Factory implements IFactory
{
	public function new(protocol:Class<IProtocol>)
	{
		this.protocol = protocol;
	}

	public function buildProtocol():IProtocol
	{
		return Type.createInstance(protocol, []);
	}

	private var protocol:Class<IProtocol>;
}