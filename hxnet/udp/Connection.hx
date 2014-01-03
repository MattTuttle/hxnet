package hxnet.udp;

import sys.net.UdpSocket;
import sys.net.Address;
import haxe.io.Bytes;

class Connection implements hxnet.interfaces.IConnection
{
	public function new(socket:UdpSocket, address:Address)
	{
		this.socket = socket;
		this.socket.setBlocking(false);
		this.address = address;
	}

	public function writeBytes(bytes:Bytes)
	{
		socket.sendTo(bytes, 0, bytes.length, address);
	}

	public function close()
	{
		socket.close();
	}

	private var socket:UdpSocket;
	private var address:Address;
}