package hxnet.interfaces;

import haxe.io.Bytes;

interface Connection
{
	public function writeBytes(bytes:Bytes):Bool;
	public function close():Void;
}