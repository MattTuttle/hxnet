package hxnet.udp;

import haxe.io.Bytes;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

typedef RemoteAddress = {
	var address:String;
	var port:Int;
}

class Socket
{

	#if neko
	public static function loadNekoAPI()
	{
		var init =  neko.Lib.load("hxNet", "neko_init", 5);

		if (init != null)
			init(function(s) return new String(s), function(len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; }, null, true, false);
		else
			throw("Could not find NekoAPI interface.");
	}
	#end

	public function new():Void
	{
		#if neko
		// initializes neko for alloc_bool...
		loadNekoAPI();
		#end
		handle = hxnet_udp_new();
	}

	public function close():Bool
	{
		return hxnet_udp_close(handle);
	}

	public function create():Bool
	{
		return hxnet_udp_create(handle);
	}

	public function connect(host:String, port:Int):Bool
	{
		return hxnet_udp_connect(handle, host, port);
	}

	public function connectMcast(mcast:String, port:Int):Bool
	{
		return hxnet_udp_connectmcast(handle, mcast, port);
	}

	public function bind(port:Int):Bool
	{
		return hxnet_udp_bind(handle, port);
	}

	/**
	 * Return the number of Bytes it sent.
	 */
	public function bindMcast(mcast:String, usPort:Int):Bool
	{
		return hxnet_udp_bindmcast(handle, mcast, usPort);
	}

	/**
	 * Return the number of Bytes it sent.
	 */
	public function send(buffer:Bytes):Int
	{
		return hxnet_udp_send(handle, buffer.getData(), buffer.length);
	}

	/**
	 * All data will be sent.
	 */
	public function sendAll(buffer:Bytes):Int
	{
		return hxnet_udp_sendall(handle, buffer.getData(), buffer.length);
	}

	public function receive(buffer:Bytes):Int
	{
		return hxnet_udp_receive(handle, buffer.getData(), buffer.length);
	}

	/**
	 * Timeout send
	 */
	public var timeoutSend(get, set):Int;
	private inline function set_timeoutSend(value:Int):Int
	{
		return hxnet_udp_settimeoutsend(handle, value);
	}
	private inline function get_timeoutSend():Int
	{
		return hxnet_udp_gettimeoutsend(handle);
	}

	/**
	 * Timeout receive
	 */
	public var timeoutReceive(get, set):Int;
	private inline function set_timeoutReceive(value:Int):Int
	{
		return hxnet_udp_settimeoutreceive(handle, value);
	}
	private inline function get_timeoutReceive():Int
	{
		return hxnet_udp_gettimeoutreceive(handle);
	}

	/**
	 * Remote address
	 */
	public var remoteAddress(get, never):RemoteAddress;
	private inline function get_remoteAddress():RemoteAddress
	{
		return hxnet_udp_getremoteaddr(handle);
	}

	/**
	 * Send buffer size
	 */
	public var sendBufferSize(get, set):Int;
	private inline function set_sendBufferSize(value:Int):Int
	{
		return hxnet_udp_setsendbuffersize(handle, value);
	}
	private inline function get_sendBufferSize():Int
	{
		return hxnet_udp_getsendbuffersize(handle);
	}

	/**
	 * Size of receiving buffer
	 */
	public var receiveBufferSize(get, set):Int;
	private inline function set_receiveBufferSize(value:Int):Int
	{
		return hxnet_udp_setreceivebuffersize(handle, value);
	}
	private inline function get_receiveBufferSize():Int
	{
		return hxnet_udp_getreceivebuffersize(handle);
	}

	public function setReuseAddress(allowReuse:Bool):Bool
	{
		return hxnet_udp_setreuseaddress(handle, allowReuse);
	}

	public function setEnableBroadcast(enableBroadcast:Bool):Bool
	{
		return hxnet_udp_setenablebroadcast(handle, enableBroadcast);
	}

	/**
	 * Set non-blocking mode
	 */
	public var nonBlocking(default, set):Bool = true;
	private inline function set_nonBlocking(value:Bool):Bool
	{
		nonBlocking = value;
		return hxnet_udp_setnonblocking(handle, value);
	}

	public var maxMessageSize(get, never):Int;
	private inline function get_maxMessageSize():Int
	{
		return hxnet_udp_getmaxmsgsize(handle);
	}

	/**
	 * Set Time-To-Live (TTL)
	 */
	public var TTL(get, set):Int;
	private inline function get_TTL():Int
	{
		return hxnet_udp_getttl(handle);
	}
	private inline function set_TTL(value:Int):Int
	{
		return hxnet_udp_setttl(handle, value);
	}

	private var handle:Dynamic;

	private static var hxnet_udp_new = Lib.load("hxnet", "hxnet_udp_new", 0);
	private static var hxnet_udp_close = Lib.load("hxnet", "hxnet_udp_close", 1);
	private static var hxnet_udp_create = Lib.load("hxnet", "hxnet_udp_create", 1);
	private static var hxnet_udp_connect = Lib.load("hxnet", "hxnet_udp_connect", 3);
	private static var hxnet_udp_connectmcast = Lib.load("hxnet", "hxnet_udp_connectmcast", 3);
	private static var hxnet_udp_bind = Lib.load("hxnet", "hxnet_udp_bind", 2);
	private static var hxnet_udp_bindmcast = Lib.load("hxnet", "hxnet_udp_bindmcast", 3);
	private static var hxnet_udp_send = Lib.load("hxnet", "hxnet_udp_send", 3);
	private static var hxnet_udp_sendall = Lib.load("hxnet", "hxnet_udp_sendall", 3);
	private static var hxnet_udp_receive = Lib.load("hxnet", "hxnet_udp_receive", 3);
	private static var hxnet_udp_settimeoutsend = Lib.load("hxnet", "hxnet_udp_settimeoutsend", 2);
	private static var hxnet_udp_settimeoutreceive = Lib.load("hxnet", "hxnet_udp_settimeoutreceive", 2);
	private static var hxnet_udp_gettimeoutsend = Lib.load("hxnet", "hxnet_udp_gettimeoutsend", 1);
	private static var hxnet_udp_gettimeoutreceive = Lib.load("hxnet", "hxnet_udp_gettimeoutreceive", 1);
	private static var hxnet_udp_getremoteaddr = Lib.load("hxnet", "hxnet_udp_getremoteaddr", 1);
	private static var hxnet_udp_setreceivebuffersize = Lib.load("hxnet", "hxnet_udp_setreceivebuffersize", 2);
	private static var hxnet_udp_setsendbuffersize = Lib.load("hxnet", "hxnet_udp_setsendbuffersize", 2);
	private static var hxnet_udp_getreceivebuffersize = Lib.load("hxnet", "hxnet_udp_getreceivebuffersize", 1);
	private static var hxnet_udp_getsendbuffersize = Lib.load("hxnet", "hxnet_udp_getsendbuffersize", 1);
	private static var hxnet_udp_setreuseaddress = Lib.load("hxnet", "hxnet_udp_setreuseaddress", 2);
	private static var hxnet_udp_setenablebroadcast = Lib.load("hxnet", "hxnet_udp_setenablebroadcast", 2);
	private static var hxnet_udp_setnonblocking = Lib.load("hxnet", "hxnet_udp_setnonblocking", 2);
	private static var hxnet_udp_getmaxmsgsize = Lib.load("hxnet", "hxnet_udp_getmaxmsgsize", 1);
	private static var hxnet_udp_getttl = Lib.load("hxnet", "hxnet_udp_getttl", 1);
	private static var hxnet_udp_setttl = Lib.load("hxnet", "hxnet_udp_setttl", 2);

}
