package hxnet.zeroconf;

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

#if (mac || ios)

class Bonjour
{

	public var domain(default, null):String;
	public var type(default, null):String;
	public var name(default, null):String;
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

#elseif android

class NsdService
{

	private var __create_func:Dynamic;
	public function new(context:Dynamic, type:String, name:String)
	{
		if (__create_func == null)
			__create_func = openfl.utils.JNI.createStaticMethod("hxnet.NsdService", "<init>", "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V", true);
		var a = new Array<Dynamic>();
		a.push(context);
		a.push(type);
		a.push(name);
		__jobject = __create_func(a);
	}

	private var __registerService:Dynamic;
	public function registerService(port:Int)
	{
		if (__registerService == null)
			__registerService = openfl.utils.JNI.createMemberMethod("hxnet.NsdService", "registerService", "(I)V", true);
		var a = new Array<Dynamic>();
		a.push(__jobject);
		a.push(port);
		__registerService(a);
	}

	private var __discoverServices:Dynamic;
	public function discoverServices()
	{
		if (__discoverServices == null)
			__discoverServices = openfl.utils.JNI.createMemberMethod("hxnet.NsdService", "discoverServices", "()V", true);
		var a = new Array<Dynamic>();
		a.push(__jobject);
		__discoverServices(a);
	}

	private var __stopService:Dynamic;
	public function stopService()
	{
		if (__stopService == null)
			__stopService = openfl.utils.JNI.createMemberMethod("hxnet.NsdService", "stopService", "()V", true);
		var a = new Array<Dynamic>();
		a.push(__jobject);
		__stopService(a);
	}

	public var __jobject:Dynamic;

}

class Bonjour
{

	public var domain(default, null):String;
	public var type(default, null):String;
	public var name(default, null):String;

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
		// TODO: don't depend on lime
		var getContext = openfl.utils.JNI.createStaticMethod("org.haxe.lime.GameActivity", "getContext", "()Landroid/content/Context;", true);
		service = new NsdService(getContext(), type, name);
		_listeners = new Map<String, Array<BonjourCallback>>();
	}

	public function publish(port:Int)
	{
		service.registerService(port);
	}

	public function resolve(timeout:Float = 0.0)
	{
		// TODO: handle timeout??
		service.discoverServices();
	}

	public function stop()
	{
		service.stopService();
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

	private var service:NsdService;
	private var _listeners:Map<String, Array<BonjourCallback>>;

}

#end
