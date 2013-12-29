package hxnet.udp;

import hxnet.udp.Socket;
import haxe.io.Bytes;

class Connection implements hxnet.interfaces.IConnection
{
	public function new(socket:Socket)
	{
		this.socket = socket;
	}

	public function writeBytes(bytes:Bytes)
	{
		socket.send(bytes);
	}

	public function close()
	{
		socket.close();
	}

	private var socket:Socket;
}