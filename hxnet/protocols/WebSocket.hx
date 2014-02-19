package hxnet.protocols;

import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Eof;
import hxnet.interfaces.IConnection;

#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#end

class WebSocket extends BaseProtocol
{
	private static var WEBSOCKET_VERSION = 13;

	private static var OPCODE_CONTINUE = 0x0;
	private static var OPCODE_TEXT = 0x1;
	private static var OPCODE_BINARY = 0x2;
	private static var OPCODE_CLOSE = 0x8;
	private static var OPCODE_PING = 0x9;
	private static var OPCODE_PONG = 0xA;

	private var headersSent:Bool = false;

	private var host:String;
	private var url:String;
	private var port:Int;
	private var key:String;
	private var origin:String;

	public function new(url:String, host:String, port:Int, origin:String, key:String="key")
	{
		super();

		this.host = host;
		this.url = url;
		this.port = port;
		this.key = key;
		this.origin = origin;
	}

	override public function isBlocking():Bool
	{
		return true;
	}

	override public function makeConnection(cnx:IConnection)
	{
		super.makeConnection(cnx);

		var headers = new Array<String>();

		headers.push("GET " + url + " HTTP/1.1");
		headers.push("Host: " + host + ":" + port);
		headers.push("Upgrade: websocket");
		headers.push("Connection: Upgrade");
		headers.push("Sec-WebSocket-Key: " + encodeBase64(key));
		headers.push("Sec-WebSocket-Version: " + WEBSOCKET_VERSION);
		headers.push("Origin: " + origin);

		// send headers
		var header = headers.join("\r\n") + "\r\n\r\n";
		cnx.writeBytes(Bytes.ofString(header));

		headersSent = true;
	}

	override public function dataReceived(input:Input)
	{
		if (headersSent)
		{
			var line:String;
			while((line = input.readLine()) != "")
			{
				// trace(line);
			}
			headersSent = false;
		}

		// loop until we get text or binary data
		var frame = recvFrame(input);

		switch (frame.opcode)
		{
			case WebSocket.OPCODE_CONTINUE: // continuation
				// return frame.bytes.toString();
				throw "Continuation should be handled by recvFrame()";
			case WebSocket.OPCODE_TEXT: // text
				recvText(frame.bytes.toString());
			case WebSocket.OPCODE_BINARY: // binary
				recvBinary(frame.bytes);
			case WebSocket.OPCODE_CLOSE: // close
				cnx.close();
			case WebSocket.OPCODE_PING: // ping
				sendFrame(WebSocket.OPCODE_PONG); // send pong
			case WebSocket.OPCODE_PONG: // pong
				// do nothing
			default:
				throw "Unsupported websocket opcode: " + frame.opcode;
		}
	}

	private function recvText(text:String) { }

	private function recvBinary(data:Bytes) { }

	public function sendText(text:String)
	{
		sendFrame(0x1, Bytes.ofString(text));
	}

	public function sendBinary(bytes:Bytes)
	{
		sendFrame(0x2, bytes);
	}

	private function sendFrame(opcode:Int, ?bytes:haxe.io.Bytes)
	{
		var bytes = new BytesOutput();
		var length = 0;
		opcode |= 0x80;
		bytes.writeByte(opcode);
		if (bytes != null)
		{
			length = bytes.length;
		}
		bytes.writeByte(length);

		cnx.writeBytes(bytes.getBytes());
	}

	private inline function recvFrame(input:Input)
	{
		var opcode = input.readByte();
		var len = input.readByte();

		var final = opcode & 0x80 != 0;
		opcode = opcode & 0x0F;
		var mask = len >> 7 == 1;
		len = len & 0x7F;

		if (len == 126)
		{
			var lenByte0 = input.readByte();
			var lenByte1 = input.readByte();
			len = (lenByte0 << 8) + lenByte1;
		}
		else if (len > 126)
		{
			var lenByte0 = input.readByte();
			var lenByte1 = input.readByte();
			var lenByte2 = input.readByte();
			var lenByte3 = input.readByte();
			len = (lenByte0 << 24) + (lenByte1 << 16) + (lenByte2 << 8) + lenByte3;
		}

		var maskKey = (mask ? input.read(4) : null);

		var payload = input.read(len);

		if (mask)
		{
			// unmask data
			for (i in 0...payload.length)
			{
				payload.set(i, payload.get(i) ^ maskKey.get(i % 4));
			}
		}

		return {
			opcode: opcode,
			mask: mask,
			final: final,
			bytes: payload
		};
	}

	private function encodeBase64(content:String) : String
	{
		var suffix = switch (content.length % 3)
		{
			case 2: "=";
			case 1: "==";
			default: "";
		};
		return BaseCode.encode(content, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/") + suffix;
	}
}