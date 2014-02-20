package hxnet.base;

import hxnet.interfaces.IConnection;
import haxe.io.Input;

class Protocol implements hxnet.interfaces.IProtocol
{

	public function new() { }

	public function isBlocking():Bool { return false; }

	public function isConnected():Bool { return this.cnx != null; }

	public function dataReceived(input:Input) { }

	public function makeConnection(cnx:IConnection) { this.cnx = cnx; }

	public function loseConnection(?reason:String) { this.cnx = null; }

	private var cnx:IConnection;
}