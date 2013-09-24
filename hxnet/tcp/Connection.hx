package hxnet.tcp;

import sys.net.Socket;
import haxe.io.Bytes;

class Connection implements hxnet.Connection
{

	public function new(socket:Socket)
	{
		this.socket = socket;
	}

	public function writeBytes(bytes:Bytes)
	{
		try
		{
			socket.output.writeBytes(bytes, 0, bytes.length);
		}
		catch (e:Dynamic)
		{
			#if debug
			trace("Error writing to socket: " + e);
			#end
		}
	}

	public function close()
	{
		socket.close();
	}

	private var socket:Socket;

}