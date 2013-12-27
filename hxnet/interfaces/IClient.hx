package hxnet.interfaces;

interface IClient
{
	public function connect(?hostname:String, ?port:Null<Int>):Void;
	public function update():Void;
	public function close():Void;
}
