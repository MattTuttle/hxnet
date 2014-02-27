package hxnet.protocols;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;

#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#end

/**
 * Remote Procedure Call protocol
 */
class RPC extends hxnet.base.Protocol
{

	/**
	 * The object to call methods on. Defaults to the RPC protocol object.
	 */
	public var dispatcher:Dynamic = this;

	/**
	 * When a full packet is received the method and arguments are read and executed.
	 */
	override private function packetReceived(input:Input)
	{
		var func = readString(input);
		var numArgs = input.readInt16();
		var arguments = new Array<Dynamic>();
		while (numArgs > 0)
		{
			switch(input.readInt8())
			{
				case TYPE_INT:
					arguments.push(input.readInt32());
				case TYPE_FLOAT:
					arguments.push(input.readFloat());
				case TYPE_BOOL:
					arguments.push(input.readInt8() == 1 ? true : false);
				case TYPE_STRING:
					arguments.push(readString(input));
				case TYPE_BYTES:
					var length = input.readInt32();
					var bytes = Bytes.alloc(length);
					input.readFullBytes(bytes, 0, length);
					arguments.push(bytes);
				case TYPE_OBJECT:
					arguments.push(haxe.Unserializer.run(readString(input)));
			}
			numArgs -= 1;
		}

		dispatch(func, arguments);
	}

	/**
	 * Dispatches a method with arguments
	 * @throws Invalid calls when dispatcher object does not contain the method or the declaration doesn't match the number of arguments passed.
	 */
	private inline function dispatch(func:String, arguments:Array<Dynamic>)
	{
		try
		{
			var rpcCall = Reflect.field(dispatcher, func);
			if (rpcCall != null)
			{
				Reflect.callMethod(dispatcher, rpcCall, arguments);
			}
		}
		catch (e:Dynamic)
		{
			// most likely an invalid call was made
			#if debug
			Lib.print(e);
			Lib.print(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			Lib.print("\n");
			#end
		}
	}

	/**
	 * Calls a procedure remotely through connection
	 * @param method     The method to call on the remote end
	 * @param arguments  The method arguments to use on the remote end
	 */
	public function call(method:String, ?arguments:Array<Dynamic>)
	{
		if (arguments == null) arguments = [];

		var o = new BytesOutput();
		writeString(o, method);
		o.writeInt16(arguments.length);
		for (arg in arguments)
		{
			if (Std.is(arg, Float))
			{
				o.writeInt8(TYPE_FLOAT);
				o.writeFloat(arg);
			}
			else if (Std.is(arg, Int))
			{
				o.writeInt8(TYPE_INT);
				o.writeInt32(arg);
			}
			else if (Std.is(arg, Bool))
			{
				o.writeInt8(TYPE_BOOL);
				o.writeInt8(arg == true ? 1 : 0);
			}
			else if (Std.is(arg, String))
			{
				o.writeInt8(TYPE_STRING);
				writeString(o, arg);
			}
			else if (Std.is(arg, Bytes))
			{
				o.writeInt8(TYPE_BYTES);
				o.writeInt32(arg.length);
				o.writeFullBytes(arg, 0, arg.length);
			}
			else
			{
				o.writeInt8(TYPE_OBJECT);
				writeString(o, haxe.Serializer.run(arg));
			}
		}

		cnx.writeBytes(o.getBytes(), true);
	}

	/**
	 * Convenience method to read string from input
	 * @param i Input object to read from
	 */
	private inline function readString(i:Input):String
	{
		var len = i.readInt32();
		return i.readString(len);
	}

	/**
	 * Convenience method to write string to output
	 * @param o Output object to write to
	 * @param value String value to write
	 */
	private inline function writeString(o:BytesOutput, value:String)
	{
		o.writeInt32(value.length);
		o.writeString(value);
	}

	// data types
    private static inline var TYPE_INT:Int    = 1;
    private static inline var TYPE_FLOAT:Int  = 2;
    private static inline var TYPE_BOOL:Int   = 3;
    private static inline var TYPE_STRING:Int = 4;
    private static inline var TYPE_BYTES:Int  = 5;
    private static inline var TYPE_OBJECT:Int = 6;
}
