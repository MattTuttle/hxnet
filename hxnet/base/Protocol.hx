package hxnet.base;

import hxnet.interfaces.Connection;
import haxe.io.Input;

class Protocol implements hxnet.interfaces.Protocol
{

	public function new() { }

	public function isConnected():Bool { return this.cnx != null; }

	public function dataReceived(input:Input) { }

	public function makeConnection(cnx:Connection) { this.cnx = cnx; }

	public function loseConnection(?reason:String) { this.cnx = null; }

	private var cnx:Connection;
}
