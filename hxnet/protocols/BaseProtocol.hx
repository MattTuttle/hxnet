package hxnet.protocols;

import hxnet.interfaces.IConnection;
import haxe.io.Input;

class BaseProtocol implements hxnet.interfaces.IProtocol
{

	public function new() { }

	public function isBlocking():Bool { return false; }

	public function dataReceived(input:Input) { }

	public function makeConnection(cnx:IConnection) { this.cnx = cnx; }

	public function loseConnection(?reason:String) { this.cnx = null; }

	private var cnx:IConnection;
}