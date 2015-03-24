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

enum Opcode
{
	Continue;
	Text(text:String);
	Binary(data:Bytes);
	Close;
	Ping;
	Pong;
}

/**
 * WebSocket protocol (RFC 6455)
 */
class WebSocket extends hxnet.base.Protocol
{

	/**
	 * Construct the WebSocket protocol
	 */
	public function new()
	{
		super();

		// _key = Base64.encode(Bytes.ofString(key));
		_headers = new Array<String>();
	}

	/**
	 * Set an HTTP header value
	 * @param String key   The header key value
	 * @param String value The header value
	 */
	function setHeader(key:String, value:String):Void
	{
		_headers.push(key + ": " + value);
	}

	/**
	 * Write out the http header
	 * @param  String http The version/status line of the http header
	 */
	function writeHeader(http:String):Void
	{
		_headers.insert(0, http);
		cnx.writeBytes(Bytes.ofString(_headers.join("\r\n") + "\r\n\r\n"));
		_headers = new Array<String>();
	}

	/**
	 * Upon connecting with another WebSocket send handshake
	 * @param cnx The remote connection
	 */
	override public function onConnect(cnx:Connection):Void
	{
		super.onConnect(cnx);

		setHeader("Host", _host + ":" + _port);
		setHeader("Upgrade", "websocket");
		setHeader("Connection", "Upgrade");
		setHeader("Sec-WebSocket-Key", _key);
		setHeader("Sec-WebSocket-Version", WEBSOCKET_VERSION);
		setHeader("Origin", _origin);

		// send headers
		writeHeader("GET " + _url + " HTTP/1.1");
		onHandshake();
	}

	/**
	 * Called after handshake is send. Must be called from an override.
	 */
	private function onHandshake():Void
	{
		_useHttp = false;
	}

	/**
	 * When data is received for the protocol this method is called.
	 * @param input The input data
	 */
	override public function dataReceived(input:Input):Void
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
			onHandshake();
		}
		else
		{
			// websocket protocol
			switch (recvFrame(input))
			{
				case Continue: // continuation
					// return frame.bytes.toString();
					throw "Continuation should be handled by recvFrame()";
				case Text(text): // text
					recvText(text);
				case Binary(bytes): // binary
					recvBinary(bytes);
				case Close: // close
					loseConnection("close connection");
					cnx.close();
				case Ping: // ping
					cnx.writeBytes(createFrame(Pong)); // send pong
				case Pong: // pong
					// do nothing
			}
		}
	}

	/**
	 * Overridable functions for receiving text
	 */
	private function recvText(text:String):Void { }

	/**
	 * Overridable functions for receiving binary data
	 */
	private function recvBinary(data:Bytes):Void { }

	/**
	 * Sends text over connection
	 */
	public function sendText(text:String):Void
	{
		cnx.writeBytes(createFrame(Text(text)));
	}

	/**
	 * Sends binary data over connection
	 */
	public function sendBinary(bytes:Bytes):Void
	{
		cnx.writeBytes(createFrame(Binary(bytes)));
	}

	/**
	 * Sends a frame of data (text, binary, ping)
	 * @param opcode  Value of the WebSocket protocol opcode
	 * @param bytes   The data to send, if any
	 */
	public static function createFrame(opcode:Opcode):Bytes
	{
		var bytes = null;
		var out = new BytesOutput();

		out.writeByte((switch (opcode) {
			case Continue: OPCODE_CONTINUE;
			case Text(text): bytes = Bytes.ofString(text); OPCODE_TEXT;
			case Binary(data): bytes = data; OPCODE_BINARY;
			case Close: OPCODE_CLOSE;
			case Ping: OPCODE_PING;
			case Pong: OPCODE_PONG;
		}) | 0x80);

		if (bytes == null)
		{
			out.writeByte(0); // zero length since there is no data
		}
		else
		{
			var len = bytes.length;
			if (len < 0x7E)
			{
				out.writeByte(len);
			}
			else if (len < 0xFFFF)
			{
				out.writeByte(0x7E);
				out.writeByte(len >> 8 & 0xFF);
				out.writeByte(len & 0xFF);
			}
			else
			{
				throw "Can't send data this large yet";
			}

			out.writeBytes(bytes, 0, len);
		}

		return out.getBytes();
	}

	/**
	 * Reads a complete WebSocket frame
	 */
	private function recvFrame(input:Input):Opcode
	{
		var opcode = input.readByte();
		var len = input.readByte();

		var final = (opcode & 0x80) != 0; // check byte 0
		opcode = opcode & 0x0F;
		var mask = len >> 7 == 1;
		len = len & 0x7F;

		if (len == 126)
		{
			len = (input.readByte() << 8) + input.readByte();
		}
		else if (len > 126)
		{
			var high = (input.readByte() << 24) + (input.readByte() << 16) + (input.readByte() << 8) + input.readByte();
			var low = (input.readByte() << 24) + (input.readByte() << 16) + (input.readByte() << 8) + input.readByte();
			var len = haxe.Int64.make(high, low);
			trace(len);
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

		// is this separation necessary?
		return switch (opcode) {
			case OPCODE_CONTINUE: Continue;
			case OPCODE_TEXT: Text(payload.toString());
			case OPCODE_BINARY: Binary(payload);
			case OPCODE_CLOSE: Close;
			case OPCODE_PING: Ping;
			case OPCODE_PONG: Pong;
			default: throw "Unsupported websocket opcode: " + opcode;
		}
	}

	private var _host:String;
	private var _url:String;
	private var _port:Int;
	private var _key:String;
	private var _origin:String;
	private var _headers:Array<String>;
	private var _useHttp:Bool = true;

	private static inline var WEBSOCKET_VERSION = "13";

	private static inline var OPCODE_CONTINUE = 0x0;
	private static inline var OPCODE_TEXT = 0x1;
	private static inline var OPCODE_BINARY = 0x2;
	private static inline var OPCODE_CLOSE = 0x8;
	private static inline var OPCODE_PING = 0x9;
	private static inline var OPCODE_PONG = 0xA;

	private static inline var MAGIC_STRING:String = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
}
