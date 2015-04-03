Haxe networking library
=======================

WARNING: This is alpha version code and should not be used for production use.

## What is hxnet?

An extension library for Haxe to simplify setting up client/server connections. It has support for the following:

* TCP
* UDP (Haxe 3.1.x and up)
* Predefined simple protocols [RPC, Telnet]
* Terminal helper function (cursor positioning, text color, etc...)
* Easy to create custom protocols


## Client/Server Architecture

There are two supported transport layers, TCP and UDP, that hxnet uses. TCP is commonly used for reliable services like HTTP, FTP, Telnet, and a multitude of others. UDP is connectionless and used for quick unreliable data that is useful for games.

On top of the transport layers are the Client and Server classes. These handle simple connections, data transmission/retrieval, and exceptions. The UDP classes fake a connection based on data received from different ip addresses and a timeout value to determine when a connection is dropped.

When creating a Client or Server object you need to pass a Protocol to it. A protocol defines the specific interactions between a client and server. For example, you can create a custom RPC based protocol that easily calls function on the server from a client (or vice versa). Another example of a protocol would be HTTP which could generate a reply from the server to a browser.

## Example Echo Server

Let's say you want to create a basic telnet echo server. We can do so by extending the Telnet protocol and overriding the `lineReceived` function.

```haxe
class Echo extends hxnet.protocols.Telnet
{

	override private function lineReceived(line:String)
	{
		writeLine(line);
	}

	static public function main()
	{
		var server = new hxnet.tcp.Server(new hxnet.base.Factory(Echo), 4000);
		server.start();
	}

}
```

The main function creates an instance of a TCP server (port 4000) and uses the base Factory class to create a new instance of Echo for every client connection. Then it calls `start` which is a shortcut for listening on a port and updating infinitely.

## Example Client

You may want to connect to a server to retrieve data. By default hxnet blocks on all connections which can be a problem with gui applications because it will lock up the rendering. We can fix that by setting `blocking` to false.

```haxe
class Client extends hxnet.protocols.Telnet
{

	override private function lineReceived(line:String)
	{
		trace(line);
	}

	static public function main()
	{
		var client = new hxnet.tcp.Client();
		client.protocol = new Client(); // set the protocol we want to use
		client.connect("localhost", 4000);
		client.blocking = false; // important for gui clients

		while (true)
		{
			client.update();
			// add application logic here
		}
	}

}
```

## License

Copyright (C) 2013-2014 Matt Tuttle

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
