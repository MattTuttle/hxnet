package hxnet.udp;

import sys.net.UdpSocket;
import sys.net.Address;
import haxe.io.Bytes;

class Connection implements hxnet.interfaces.Connection
{
	public function new(socket:UdpSocket, address:Address)
	{
		this.socket = socket;
		this.address = address.clone();
	}

	public function writeBytes(bytes:Bytes):Bool
	{
		try
		{
			socket.sendTo(bytes, 0, bytes.length, address);
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

	private var socket:UdpSocket;
	private var address:Address;
}