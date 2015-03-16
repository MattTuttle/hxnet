package hxnet.protocols;

import haxe.crypto.Base64;
import haxe.crypto.Sha1;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Eof;
import hxnet.interfaces.Connection;

#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#end

using StringTools;

/**
 * WebSocket protocol (RFC 6455)
 */
class WebSocket extends hxnet.base.Protocol
{
	private static inline var WEBSOCKET_VERSION = "13";

	private static inline var OPCODE_CONTINUE = 0x0;
	private static inline var OPCODE_TEXT = 0x1;
	private static inline var OPCODE_BINARY = 0x2;
	private static inline var OPCODE_CLOSE = 0x8;
	private static inline var OPCODE_PING = 0x9;
	private static inline var OPCODE_PONG = 0xA;

	/**
	 * Construct the WebSocket protocol
	 */
	public function new(url:String, host:String, port:Int, origin:String, key:String="key")
	{
		super();

		_host = host;
		_url = url;
		_port = port;
		_key = Base64.encode(Bytes.ofString(key));
		_origin = origin;
		_headers = new Array<String>();
	}

	function setHeader(key:String, value:String)
	{
		_headers.push(key + ": " + value);
	}

	function writeHeader(http:String)
	{
		_headers.insert(0, http);
		cnx.writeBytes(Bytes.ofString(_headers.join("\r\n") + "\r\n\r\n"));
		_headers = new Array<String>();
		_useHttp = false;
	}

	/**
	 * Upon connecting with another WebSocket send handshake
	 * @param cnx The remote connection
	 */
	override public function makeConnection(cnx:Connection, isClient:Bool)
	{
		super.makeConnection(cnx, isClient);

		if (isClient)
		{
			setHeader("Host", _host + ":" + _port);
			setHeader("Upgrade", "websocket");
			setHeader("Connection", "Upgrade");
			setHeader("Sec-WebSocket-Key", _key);
			setHeader("Sec-WebSocket-Version", WEBSOCKET_VERSION);
			setHeader("Origin", _origin);

			// send headers
			writeHeader("GET " + _url + " HTTP/1.1");
		}
	}

	/**
	 * When data is received for the protocol this method is called.
	 * @param input The input data
	 */
	override public function dataReceived(input:Input)
	{
		if (_useHttp) // http protocol
		{
			var line:String;
			while((line = input.readLine()) != "")
			{
				var colon = line.indexOf(":");
				if (colon != -1)
				{
					var key = line.substr(0, colon).trim();
					var value = line.substr(colon + 1).trim();
					if (key == "Sec-WebSocket-Key")
					{
						var accept = Base64.encode(Sha1.make(Bytes.ofString(value + MAGIC_STRING)));
						setHeader("Upgrade", "websocket");
						setHeader("Connection", "upgrade");
						setHeader("Sec-WebSocket-Accept", accept);
					}
				}
			}
			writeHeader("HTTP/1.1 101 Switching Protocols");
		}
		else // websocket protocol
		{
			// loop until we get text or binary data
			var frame = recvFrame(input);

			switch (frame.opcode)
			{
				case OPCODE_CONTINUE: // continuation
					// return frame.bytes.toString();
					throw "Continuation should be handled by recvFrame()";
				case OPCODE_TEXT: // text
					recvText(frame.bytes.toString());
				case OPCODE_BINARY: // binary
					recvBinary(frame.bytes);
				case OPCODE_CLOSE: // close
					cnx.close();
				case OPCODE_PING: // ping
					sendFrame(OPCODE_PONG); // send pong
				case OPCODE_PONG: // pong
					// do nothing
				default:
					throw "Unsupported websocket opcode: " + frame.opcode;
			}
		}
	}

	/**
	 * Overridable functions for receiving text
	 */
	private function recvText(text:String) { }

	/**
	 * Overridable functions for receiving binary data
	 */
	private function recvBinary(data:Bytes) { }

	/**
	 * Sends text over connection
	 */
	public function sendText(text:String)
	{
		sendFrame(OPCODE_TEXT, Bytes.ofString(text));
	}

	/**
	 * Sends binary data over connection
	 */
	public function sendBinary(bytes:Bytes)
	{
		sendFrame(OPCODE_BINARY, bytes);
	}

	/**
	 * Sends a frame of data (text, binary, ping)
	 * @param opcode  Value of the WebSocket protocol opcode
	 * @param bytes   The data to send, if any
	 */
	private function sendFrame(opcode:Int, ?bytes:haxe.io.Bytes)
	{
		var out = new BytesOutput();
		var length = (bytes == null) ? 0 : bytes.length;
		opcode |= 0x80;
		out.writeByte(opcode);
		if (length < 0x7E)
		{
			out.writeByte(length);
		}
		else if (length < 0xFFFF)
		{
			out.writeByte(0x7E);
			out.writeByte(length >> 8 & 0xFF);
			out.writeByte(length & 0xFF);
		}
		else
		{
			throw "Can't send data this large";
		}

		if (bytes != null)
		{
			out.writeBytes(bytes, 0, bytes.length);
		}

		cnx.writeBytes(out.getBytes());
	}

	/**
	 * Reads a complete WebSocket frame
	 */
	private inline function recvFrame(input:Input)
	{
		var opcode = input.readByte();
		var len = input.readByte();

		var final = (opcode & 0x80) != 0; // check byte 0
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
			var lenByte4 = input.readByte();
			var lenByte5 = input.readByte();
			var lenByte6 = input.readByte();
			var lenByte7 = input.readByte();
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
			bytes: payload
		};
	}

	private var _host:String;
	private var _url:String;
	private var _port:Int;
	private var _key:String;
	private var _origin:String;
	private var _headers:Array<String>;
	private var _useHttp:Bool = true;

	static private var MAGIC_STRING:String = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
}