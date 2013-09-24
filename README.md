Haxe networking library
=======================

WARNING: The code is still in alpha status and should not be used for production use.

## What is hxnet?

An extension library for Haxe to simplify setting up client/server connections. It has support for the following:

* TCP
* UDP (pulled from hxudp)
* Bonjour service discovery and publishing [OSX, iOS]
* Custom protocols


## Client/Server Architecture

There are two supported transport layers, TCP and UDP, that hxnet uses. TCP is commonly used for reliable services like HTTP, FTP, Telnet, and a multitude of others. UDP is connectionless and used for quick unreliable data that is often useful for games.

On top of the transport layers are the Client and Server classes. These handle connections, data transmission/retrieval, and exceptions. The UDP classes fake a connection based on data received from different ip addresses.

When creating a Client or Server object you need to pass a Protocol to it. A protocol defines the specific interactions between a client and server. For example, you can create a custom RPC based protocol that easily calls function on the server from a client (or vice versa). Another example of a protocol would be HTTP which could generate a reply from the server to a browser.


## License

Copyright (C) 2013 Matt Tuttle

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
