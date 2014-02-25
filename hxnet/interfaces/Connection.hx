package hxnet.interfaces;

import haxe.io.Bytes;

interface Connection
{
	public function writeBytes(bytes:Bytes, writeLength:Bool=false):Bool;
	public function close():Void;
}