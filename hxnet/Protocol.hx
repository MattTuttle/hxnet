package hxnet;

import haxe.io.Input;

interface Protocol
{
	public function makeConnection(cnx:Connection):Void;
	public function loseConnection(?reason:String):Void;
	public function dataReceived(input:Input):Void;
}