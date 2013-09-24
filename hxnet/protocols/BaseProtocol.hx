package hxnet.protocols;

import hxnet.Connection;
import haxe.io.Input;

class BaseProtocol implements hxnet.Protocol
{
	public function new() { }

	public function makeConnection(cnx:Connection)
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

	private var cnx:Connection;
}