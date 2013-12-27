package hxnet.interfaces;

interface IClient
{
	public function connect(?hostname:String, ?port:Int):Void;
	public function update():Void;
	public function close():Void;
}
