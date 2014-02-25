package hxnet.interfaces;

import haxe.io.Bytes;

interface Connection
{
	public function writeBytes(bytes:Bytes):Void;
	public function close():Void;
}