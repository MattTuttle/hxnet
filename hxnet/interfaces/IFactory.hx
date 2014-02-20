package hxnet.interfaces;

interface IFactory
{
	public function buildProtocol():IProtocol;
}