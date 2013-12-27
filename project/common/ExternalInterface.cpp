#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>

#ifdef HX_WINDOWS
	#include <winsock.h>
#else
	#include <arpa/inet.h>
	#include <ifaddrs.h>
	#include <netdb.h>
#endif

#include "Bonjour.h"
#include "UdpSocket.h"
using namespace hxnet;

// neko types
vkind kBonjourHandle;
vkind kUdpSocket;
int _id_type,
	_id_service,
	_id_port,
	_id_address,
	_id_addresses,
	_id_ip,
	_id_ipv6;


// TODO: improve this to not use val_id?
#define FIELD_IF_EXIST(O,N,T) if (service->N) \
	alloc_field(O, val_id(#N), alloc_ ## T(service->N))

AutoGCRoot *bonjourCallback = 0;
void network_callback(const char *type, BonjourService *service)
{
	if (!bonjourCallback) return;

	value s = alloc_empty_object();
	FIELD_IF_EXIST(s, name, string);
	FIELD_IF_EXIST(s, type, string);
	FIELD_IF_EXIST(s, domain, string);
	FIELD_IF_EXIST(s, hostName, string);
	FIELD_IF_EXIST(s, port, int);

	if (service->numAddresses > 0)
	{
		value addresses = alloc_array(service->numAddresses);
		for (int i = 0; i < service->numAddresses; i++)
		{
			BonjourAddress *addr = &service->addresses[i];
			value address = alloc_empty_object();
			alloc_field(address, _id_ipv6, alloc_bool(addr->ipv6));
			alloc_field(address, _id_ip, alloc_string(addr->ip));
			alloc_field(address, _id_port, alloc_int(addr->port));
			val_array_set_i(addresses, i, address);
		}
		alloc_field(s, _id_addresses, addresses);
	}

	value o = alloc_empty_object();
	alloc_field(o, _id_type, alloc_string(type));
	alloc_field(o, _id_service, s);

	val_call1(bonjourCallback->get(), o);
}

void *objectFromAbstract(value handle, vkind kind)
{
	if (val_is_kind(handle, kind))
	{
		return val_to_kind(handle, kind);
	}
	return 0;
}

void cleanupHandle(value handle)
{
	void *bonjourHandle = objectFromAbstract(handle, kBonjourHandle);
	if (bonjourHandle)
	{
		// TODO: cleanup handle
		// stopBonjourService(bonjourHandle);
	}
}

value hxnet_bonjour_callback(value callback)
{
	if (val_is_null(callback))
	{
		if (bonjourCallback)
		{
			delete bonjourCallback;
			bonjourCallback = 0;
		}
	}
	else
	{
		bonjourCallback = new AutoGCRoot(callback);
	}
	return alloc_null();
}
DEFINE_PRIM(hxnet_bonjour_callback, 1);

value hxnet_publish_bonjour_service(value domain, value type, value name, value port)
{
	BonjourService *service = new BonjourService();
	service->domain = val_string(domain);
	service->type = val_string(type);
	service->name = val_string(name);
	service->port = val_int(port);

	void *bonjourHandle = createBonjourService(service, network_callback);
	delete service;

	if (bonjourHandle)
	{
		publishBonjourService(bonjourHandle);

		value handle = alloc_abstract(kBonjourHandle, bonjourHandle);
		val_gc(handle, cleanupHandle);
		return handle;
	}
	return alloc_null();
}
DEFINE_PRIM(hxnet_publish_bonjour_service, 4);


value hxnet_resolve_bonjour_service(value domain, value type, value name, value timeout)
{
	BonjourService *service = new BonjourService();
	service->domain = val_string(domain);
	service->type = val_string(type);
	service->name = val_string(name);

	void *bonjourHandle = createBonjourService(service, network_callback);
	if (bonjourHandle)
	{
		resolveBonjourService(bonjourHandle, val_is_float(timeout) ? val_float(timeout) : val_int(timeout));

		value handle = alloc_abstract(kBonjourHandle, bonjourHandle);
		val_gc(handle, cleanupHandle);
		return handle;
	}
	return alloc_null();
}
DEFINE_PRIM(hxnet_resolve_bonjour_service, 4);


void hxnet_bonjour_stop(value handle)
{
	void *bonjourHandle = objectFromAbstract(handle, kBonjourHandle);
	if (bonjourHandle)
	{
		stopBonjourService(bonjourHandle);
	}
}
DEFINE_PRIM(hxnet_bonjour_stop, 1);


// ----------------------------------------------------------------------------
// UDP functions
// ----------------------------------------------------------------------------

void delete_UdpSocket(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	delete s;
}

value hxnet_udp_new() {
	value handle = alloc_abstract(kUdpSocket, new UdpSocket());
	val_gc(handle, delete_UdpSocket);
	return handle;
}
DEFINE_PRIM(hxnet_udp_new, 0);

value hxnet_udp_close(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->Close() : false);
}
DEFINE_PRIM(hxnet_udp_close, 1);

value hxnet_udp_create(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->Create() : false);
}
DEFINE_PRIM(hxnet_udp_create, 1);

value hxnet_udp_connect(value a, value b, value c) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->Connect(val_string(b), val_int(c)) : false);
}
DEFINE_PRIM(hxnet_udp_connect, 3);

value hxnet_udp_connectmcast(value a, value b, value c) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->ConnectMcast(val_string(b), val_int(c)) : false);
}
DEFINE_PRIM(hxnet_udp_connectmcast, 3);

value hxnet_udp_bind(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->Bind(val_int(b)) : false);
}
DEFINE_PRIM(hxnet_udp_bind, 2);

value hxnet_udp_bindmcast(value a, value b, value c) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->BindMcast(val_string(b), val_int(c)) : false);
}
DEFINE_PRIM(hxnet_udp_bindmcast, 3);

value hxnet_udp_send(value a, value b, value c) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->Send(buffer_data(val_to_buffer(b)), val_int(c)) : 0);
}
DEFINE_PRIM(hxnet_udp_send, 3);

value hxnet_udp_sendall(value a, value b, value c) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->SendAll(buffer_data(val_to_buffer(b)), val_int(c)) : 0);
}
DEFINE_PRIM(hxnet_udp_sendall, 3);

value hxnet_udp_receive(value a, value b, value c) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->Receive(buffer_data(val_to_buffer(b)), val_int(c)) : 0);
}
DEFINE_PRIM(hxnet_udp_receive, 3);

value hxnet_udp_settimeoutsend(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	s->SetTimeoutSend(val_int(b));
	return alloc_null();
}
DEFINE_PRIM(hxnet_udp_settimeoutsend, 2);

value hxnet_udp_settimeoutreceive(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	s->SetTimeoutReceive(val_int(b));
	return alloc_null();
}
DEFINE_PRIM(hxnet_udp_settimeoutreceive, 2);

value hxnet_udp_gettimeoutsend(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->GetTimeoutSend() : 0);
}
DEFINE_PRIM(hxnet_udp_gettimeoutsend, 1);

value hxnet_udp_gettimeoutreceive(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->GetTimeoutReceive() : 0);
}
DEFINE_PRIM(hxnet_udp_gettimeoutreceive, 1);

value hxnet_udp_getremoteaddr(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	char* address = new char[INET_ADDRSTRLEN];
	int port = 0;
	s->GetRemoteAddr(address, &port);
	value o = alloc_empty_object();
	alloc_field(o, _id_address, alloc_string(address));
	alloc_field(o, _id_port, alloc_int(port));
	delete[] address;
	return o;
}
DEFINE_PRIM(hxnet_udp_getremoteaddr, 1);

value hxnet_udp_setreceivebuffersize(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->SetReceiveBufferSize(val_int(b)) : 0);
}
DEFINE_PRIM(hxnet_udp_setreceivebuffersize, 2);

value hxnet_udp_setsendbuffersize(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->SetSendBufferSize(val_int(b)) : 0);
}
DEFINE_PRIM(hxnet_udp_setsendbuffersize, 2);

value hxnet_udp_getreceivebuffersize(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->GetReceiveBufferSize() : 0);
}
DEFINE_PRIM(hxnet_udp_getreceivebuffersize, 1);

value hxnet_udp_getsendbuffersize(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->GetSendBufferSize() : 0);
}
DEFINE_PRIM(hxnet_udp_getsendbuffersize, 1);

value hxnet_udp_setreuseaddress(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->SetReuseAddress(val_bool(b)) : false);
}
DEFINE_PRIM(hxnet_udp_setreuseaddress, 2);

value hxnet_udp_setenablebroadcast(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->SetEnableBroadcast(val_bool(b)) : false);
}
DEFINE_PRIM(hxnet_udp_setenablebroadcast, 2);

value hxnet_udp_setnonblocking(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_bool(s ? s->SetNonBlocking(val_bool(b)) : false);
}
DEFINE_PRIM(hxnet_udp_setnonblocking, 2);

value hxnet_udp_getmaxmsgsize(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->GetMaxMsgSize() : 0);
}
DEFINE_PRIM(hxnet_udp_getmaxmsgsize, 1);

value hxnet_udp_getttl(value a) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->GetTTL() : 0);
}
DEFINE_PRIM(hxnet_udp_getttl, 1);

value hxnet_udp_setttl(value a, value b) {
	UdpSocket* s = (UdpSocket*) objectFromAbstract(a, kUdpSocket);
	return alloc_int(s ? s->SetTTL(val_int(b)) : 0);
}
DEFINE_PRIM(hxnet_udp_setttl, 2);

// ----------------------------------------------------------------------------
// Main function, prepares neko
// ----------------------------------------------------------------------------

extern "C" void hxnet_main() {
    _id_type      = val_id("type");
    _id_service   = val_id("service");
    _id_port      = val_id("port");
    _id_address   = val_id("address");
    _id_addresses = val_id("addresses");
    _id_ip        = val_id("ip");
    _id_ipv6      = val_id("ipv6");

	kBonjourHandle = alloc_kind();
	kUdpSocket = alloc_kind();
}
DEFINE_ENTRY_POINT(hxnet_main);

// Reference this to bring in all the symbols for the static library
extern "C" int hxnet_register_prims() { return 0; }
