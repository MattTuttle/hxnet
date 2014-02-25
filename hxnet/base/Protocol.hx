package hxnet.base;

import hxnet.interfaces.Connection;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Eof;
import haxe.io.Input;

class Protocol implements hxnet.interfaces.Protocol
{

	public function new() { }

	public function isConnected():Bool { return this.cnx != null; }

	public function dataReceived(input:Input):Void
	{
		if (_packetPos > 0)
		{
			readPacket(input);
		}

		while (initPacket(input))
		{
			readPacket(input);
		}
	}

	private function fullPacketReceived(input:Input):Void
	{

	}

	private function initPacket(input:Input):Bool
	{
		try
		{
			_packetLength = input.readInt32();
			_packet = Bytes.alloc(_packetLength);
		}
		catch (e:Eof)
		{
			return false;
		}
		return true;
	}

	private inline function readPacket(input:Input):Bool
	{
		var finish = true, byte:Int = 0;
		while (finish)
		{
			try
			{
				byte = input.readByte();
			}
			catch (e:Eof)
			{
				finish = false;
			}
			_packet.set(_packetPos, byte);
			_packetPos += 1;

			if (_packetPos >= _packetLength)
			{
				var input = new BytesInput(_packet);
				fullPacketReceived(input);
				_packetPos = 0;
				break;
			}
		}
		return finish;
	}

	public function makeConnection(cnx:Connection) { this.cnx = cnx; }

	public function loseConnection(?reason:String) { this.cnx = null; }

	private var cnx:Connection;

	private var _packetLength:Int = 0;
	private var _packetPos:Int = 0;
	private var _packet:Bytes;
}
