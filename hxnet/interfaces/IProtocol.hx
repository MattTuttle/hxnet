package hxnet.interfaces;

import haxe.io.Input;

interface IProtocol
{
	public function isBlocking():Bool;
	public function isConnected():Bool;
	public function makeConnection(cnx:IConnection):Void;
	public function loseConnection(?reason:String):Void;
	public function dataReceived(input:Input):Void;
}