package hxnet.interfaces;

import haxe.io.Input;

interface Protocol
{
	public function isBlocking():Bool;
	public function isConnected():Bool;
	public function makeConnection(cnx:Connection):Void;
	public function loseConnection(?reason:String):Void;
	public function dataReceived(input:Input):Void;
}