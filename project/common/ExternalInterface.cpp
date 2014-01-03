#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>

#include "Bonjour.h"
using namespace hxnet;

// neko types
DEFINE_KIND(kBonjourHandle);
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

void *objectFromAbstract(value handle, vkind kind)
{
	if (val_is_kind(handle, kind))
	{
		return val_to_kind(handle, kind);
	}
	return 0;
}

#if __APPLE__
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

void cleanupBonjourHandle(value handle)
{
	void *bonjourHandle = objectFromAbstract(handle, kBonjourHandle);
	if (bonjourHandle)
	{
		// TODO: cleanup handle
		// stopBonjourService(bonjourHandle);
	}
}

static void hxnet_bonjour_callback(value callback)
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
	// return alloc_null();
}

static value hxnet_publish_bonjour_service(value domain, value type, value name, value port)
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
		val_gc(handle, cleanupBonjourHandle);
		return handle;
	}
	return alloc_null();
}


static value hxnet_resolve_bonjour_service(value domain, value type, value name, value timeout)
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
		val_gc(handle, cleanupBonjourHandle);
		return handle;
	}
	return alloc_null();
}


static value hxnet_bonjour_stop(value handle)
{
	void *bonjourHandle = objectFromAbstract(handle, kBonjourHandle);
	if (bonjourHandle)
	{
		stopBonjourService(bonjourHandle);
	}
	return alloc_null();
}

DEFINE_PRIM(hxnet_bonjour_callback, 1);
DEFINE_PRIM(hxnet_publish_bonjour_service, 4);
DEFINE_PRIM(hxnet_resolve_bonjour_service, 4);
DEFINE_PRIM(hxnet_bonjour_stop, 1);

#endif // __APPLE__

// ----------------------------------------------------------------------------
// Main function, prepares neko
// ----------------------------------------------------------------------------

extern "C" {

void hxnet_main() {
    _id_type      = val_id("type");
    _id_service   = val_id("service");
    _id_port      = val_id("port");
    _id_address   = val_id("address");
    _id_addresses = val_id("addresses");
    _id_ip        = val_id("ip");
    _id_ipv6      = val_id("ipv6");

	kind_share(&kBonjourHandle, "bonjour");
}
DEFINE_ENTRY_POINT(hxnet_main);

// Reference this to bring in all the symbols for the static library
int hxnet_register_prims()
{
	static bool init = false;
	if (init) return 0;
	init = true;

	hxnet_main();
	return 0;
}

}
