package hxnet.tcp;

import sys.net.Socket;
import haxe.io.Bytes;

class Connection implements hxnet.interfaces.Connection
{

	public function new(socket:Socket)
	{
		this.socket = socket;
	}

	public function writeBytes(bytes:Bytes, writeLength:Bool=false):Bool
	{
		try
		{
			if (writeLength) socket.output.writeInt32(bytes.length);
			socket.output.writeBytes(bytes, 0, bytes.length);
		}
		catch (e:Dynamic)
		{
			#if debug
			trace("Error writing to socket: " + e);
			#end
			return false;
		}
		return true;
	}

	public function close()
	{
		socket.close();
	}

	private var socket:Socket;

}