package hxnet.protocols;

import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.Eof;

class RPC extends BaseProtocol
{

	public override function dataReceived(input:Input)
	{
		try
		{
			while (true)
			{
				var func = readString(input);
				var numArgs = input.readInt16();
				var arguments = new Array<Dynamic>();
				for (i in 0...numArgs)
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
				}
				var rpcCall = Reflect.field(this, func);
				if (rpcCall != null)
				{
					Reflect.callMethod(this, rpcCall, arguments);
				}
			}
		}
		catch (e:Eof)
		{
			// not an error, just end of data
		}
		catch (e:Dynamic)
		{
			// most likely an invalid call was made
			#if debug
			trace("RPC Error: " + e);
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
			else
			{
				o.writeInt8(TYPE_OBJECT);
				writeString(o, haxe.Serializer.run(arg));
			}
		}
		cnx.writeBytes(o.getBytes());
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

    private static inline var TYPE_INT:Int    = 0;
    private static inline var TYPE_FLOAT:Int  = 1;
    private static inline var TYPE_BOOL:Int   = 2;
    private static inline var TYPE_STRING:Int = 3;
    private static inline var TYPE_OBJECT:Int = 4;
}