package hxnet;

#if (mac || ios)

#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#end

typedef BonjourAddress = {
	var ip:String;
	var port:Int;
	var ipv6:Bool;
};

typedef BonjourService = {
	var name:String;
	var port:Int;
	var type:String;
	var domain:String;
	@:optional var addresses:Array<BonjourAddress>;
	@:optional var hostName:String;
}

typedef BonjourCallbackData = {
	var type:String;
	var service:BonjourService;
}

typedef BonjourCallback = BonjourService->Void;

class Bonjour
{

	public var domain:String;
	public var type:String;
	public var name:String;
	public var port:Int = 0;

    public static inline var WILL_PUBLISH:String    = "willPublish";
    public static inline var DID_PUBLISH:String     = "didPublish";
    public static inline var DID_NOT_PUBLISH:String = "didNotPublish";
    public static inline var WILL_RESOLVE:String    = "willResolve";
    public static inline var DID_RESOLVE:String     = "didResolve";
    public static inline var DID_NOT_RESOLVE:String = "didNotResolve";
    public static inline var DID_STOP:String        = "didStop";

	public function new(domain:String, type:String, name:String)
	{
		this.domain = domain;
		this.type = type;
		this.name = name;
		_listeners = new Map<String, Array<BonjourCallback>>();
		hxnet_bonjour_callback(bonjour_callback);
	}

	public function publish(port:Int)
	{
		stop();
		_handle = hxnet_publish_bonjour_service(domain, type, name, port);
	}

	public function resolve(timeout:Float = 0.0)
	{
		stop();
		_handle = hxnet_resolve_bonjour_service(domain, type, name, timeout);
	}

	public function stop()
	{
		if (_handle != null)
		{
			hxnet_bonjour_stop(_handle);
			_handle = null;
		}
	}

	public function addEventListener(event:String, callback:BonjourCallback)
	{
		var callbacks:Array<BonjourCallback>;
		if (_listeners.exists(event))
		{
			callbacks = _listeners.get(event);
		}
		else
		{
			callbacks = new Array<BonjourCallback>();
			_listeners.set(event, callbacks);
		}
		callbacks.push(callback);
	}

	public function removeEventListener(event:String, callback:BonjourCallback)
	{
		if (_listeners.exists(event))
		{
			var callbacks = _listeners.get(event);
			callbacks.remove(callback);
		}
	}

	private function dispatchEvent(event:String, service:BonjourService)
	{
		if (_listeners.exists(event))
		{
			var callbacks = _listeners.get(event);
			for (callback in callbacks)
			{
				callback(service);
			}
		}
	}

	private function bonjour_callback(e:BonjourCallbackData)
	{
		#if neko
		e = neko.Lib.nekoToHaxe(e);
		#end
		dispatchEvent(e.type, e.service);
	}

	private var _handle:Dynamic = null;
	private var _listeners:Map<String, Array<BonjourCallback>>;

	private static var hxnet_bonjour_callback = Lib.load("hxnet", "hxnet_bonjour_callback", 1);
	private static var hxnet_resolve_bonjour_service = Lib.load("hxnet", "hxnet_resolve_bonjour_service", 4);
	private static var hxnet_publish_bonjour_service = Lib.load("hxnet", "hxnet_publish_bonjour_service", 4);
	private static var hxnet_bonjour_stop = Lib.load("hxnet", "hxnet_bonjour_stop", 1);

}

#end
