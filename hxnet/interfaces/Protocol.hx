package hxnet.interfaces;

import haxe.io.Input;

interface Protocol
{
	public function isConnected():Bool;
	public function makeConnection(cnx:Connection, isClient:Bool):Void;
	public function loseConnection(?reason:String):Void;
	public function dataReceived(input:Input):Void;
}