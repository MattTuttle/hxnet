package hxnet.interfaces;

import haxe.io.Bytes;

interface IConnection
{
	public function writeBytes(bytes:Bytes):Void;
	public function close():Void;
}