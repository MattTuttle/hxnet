#ifndef __BONJOURH__
#define __BONJOURH__

namespace hxnet
{

	typedef struct {
		bool ipv6;
		char *ip;
		int port;
	} BonjourAddress;

	typedef struct {
		const char *domain;
		const char *type;
		const char *hostName;
		const char *name;
		BonjourAddress *addresses;
		int numAddresses;
		int port;
	} BonjourService;

	typedef void (*BonjourCallback)(const char *type, BonjourService *service);

	void *createBonjourService(BonjourService *service, BonjourCallback callback);
	void publishBonjourService(void *handle);
	void resolveBonjourService(void *handle, float timeout);
	void stopBonjourService(void *bonjourHandle);

}

#endif
