package hxnet.interfaces;

interface Server
{
	public function update(timeout:Float=1):Void;
	public function close():Void;
}
