package hxnet.interfaces;

import haxe.io.Input;

interface IProtocol
{
	public function makeConnection(cnx:IConnection):Void;
	public function loseConnection(?reason:String):Void;
	public function dataReceived(input:Input):Void;
}