package hxnet.protocols;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Input;

#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#end

class RPC extends hxnet.base.Protocol
{

	public var dispatcher:Dynamic;

	override private function fullPacketReceived(input:Input)
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
				case TYPE_OBJECT:
					arguments.push(haxe.Unserializer.run(readString(input)));
			}
			numArgs -= 1;
		}

		dispatch(func, arguments);
	}

	private inline function dispatch(func:String, arguments:Array<Dynamic>)
	{
		if (dispatcher == null) dispatcher = this;

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

	public function call(func:String, ?arguments:Array<Dynamic>)
	{
		if (arguments == null) arguments = [];

		var o = new BytesOutput();
		writeString(o, func);
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

	private inline function readString(i:Input):String
	{
		var len = i.readInt32();
		return i.readString(len);
	}

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
