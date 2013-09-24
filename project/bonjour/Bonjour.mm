#import <Foundation/Foundation.h>
#import <arpa/inet.h>
#import "Bonjour.h"
using namespace hxnet;

typedef union {
	struct sockaddr sa;
	struct sockaddr_in ipv4;
	struct sockaddr_in6 ipv6;
} ip_socket_address;

BonjourService *create_service(NSNetService *netService)
{
	BonjourService *service = new BonjourService();
	memset(service, 0, sizeof(BonjourService));

	service->name = [netService.name UTF8String];
	service->hostName = [netService.hostName UTF8String];
	service->type = [netService.type UTF8String];
	service->domain = [netService.domain UTF8String];
	service->port = netService.port;

	// get ip addresses
	service->numAddresses = netService.addresses.count;
	service->addresses = new BonjourAddress[service->numAddresses];
	int i = 0;
	char addressBuffer[INET6_ADDRSTRLEN];
	for (NSData *address in netService.addresses)
	{
		ip_socket_address *socketAddress = (ip_socket_address *)[address bytes];
		if (socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6))
		{
			BonjourAddress *addr = &service->addresses[i];

			memset(addressBuffer, 0, INET6_ADDRSTRLEN);
			inet_ntop(
				socketAddress->sa.sa_family,
				(socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
				addressBuffer,
				sizeof(addressBuffer));
			addr->ip = new char[strlen(addressBuffer)];
			addr->port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
			addr->ipv6 = socketAddress->sa.sa_family == AF_INET6;
			strcpy(addr->ip, addressBuffer);
			i += 1;
		}
	}

	return service;
}

void free_service(BonjourService *service)
{
	for (int i = 0; i < service->numAddresses; i++)
	{
		delete [] service->addresses[i].ip;
	}
	delete [] service->addresses;
	delete service;
}

@interface Bonjour : NSObject <NSNetServiceDelegate, NSStreamDelegate> {
	BonjourCallback _callback;
	void *_data;
}

@end

@implementation Bonjour

- (id)initWithCallback:(BonjourCallback)callback data:(void *)data {
	if (self = [super init])
	{
		_callback = callback;
		_data = data;
	}
	return self;
}

- (void)callbackWithType:(NSString *)type sender:(NSNetService *)sender {
	if (_callback)
	{
		BonjourService *service = create_service(sender);
		_callback(_data, [type UTF8String], service);
		free_service(service);
	}
}

- (void)netServiceWillPublish:(NSNetService *)sender {
	[self callbackWithType:@"willPublish" sender:sender];
}

- (void)netServiceDidPublish:(NSNetService *)sender {
	[self callbackWithType:@"didPublish" sender:sender];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	[self callbackWithType:@"didNotPublish" sender:sender];
}

- (void)netServiceWillResolve:(NSNetService *)sender {
	[self callbackWithType:@"willResolve" sender:sender];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
	[self callbackWithType:@"didResolve" sender:sender];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	[self callbackWithType:@"didNotResolve" sender:sender];
}

- (void)netServiceDidStop:(NSNetService *)sender {
	[self callbackWithType:@"didStop" sender:sender];
}
@end

namespace hxnet
{

	void *createBonjourService(BonjourService *service, BonjourCallback callback, void *userData)
	{
		NSString *nsDomain = [NSString stringWithUTF8String:service->domain];
		NSString *nsType = [NSString stringWithUTF8String:service->type];
		NSString *nsName = [NSString stringWithUTF8String:service->name];
		NSNetService *ns = [[NSNetService alloc] initWithDomain:nsDomain type:nsType name:nsName port:service->port];

		Bonjour *delegate = [[Bonjour alloc] initWithCallback:callback data:userData];
		[ns setDelegate:delegate];

		return ns;
	}

	void publishBonjourService(void *bonjourHandle)
	{
		NSNetService *ns = (NSNetService *)bonjourHandle;
		if (ns) [ns publish];
	}

	void resolveBonjourService(void *bonjourHandle, float timeout)
	{
		NSNetService *ns = (NSNetService *)bonjourHandle;
		if (ns) [ns resolveWithTimeout:timeout];
	}

	void stopBonjourService(void *bonjourHandle)
	{
		NSNetService *ns = (NSNetService *)bonjourHandle;
		if (ns) [ns stop];
	}

}
