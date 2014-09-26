package hxnet.interfaces;

import haxe.io.Bytes;

interface Connection
{
	public function isOpen():Bool;
	public function writeBytes(bytes:Bytes, writeLength:Bool=false):Bool;
	public function close():Void;
}
