package hxnet.protocols;

import hxnet.interfaces.IConnection;
import haxe.io.Input;

class BaseProtocol implements hxnet.interfaces.IProtocol
{
	public function new() { }

	public function makeConnection(cnx:IConnection)
	{
		this.cnx = cnx;
	}

	public function dataReceived(input:Input)
	{
	}

	public function loseConnection(?reason:String)
	{
		this.cnx = null;
	}

	private var cnx:IConnection;
}