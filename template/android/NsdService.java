package hxnet;

import android.content.Context;
import android.net.nsd.NsdServiceInfo;
import android.net.nsd.NsdManager;
import android.util.Log;

public class NsdService
{
	Context mContext;
	NsdManager mNsdManager;
	NsdServiceInfo mServiceInfo;

	String mServiceName;
	String mServiceType;

	NsdManager.ResolveListener mResolveListener;
	NsdManager.DiscoveryListener mDiscoveryListener;
	NsdManager.RegistrationListener mRegistrationListener;

	public static final String TAG = "NsdService";

	public NsdService(Context context, String serviceType, String serviceName)
	{
		mContext = context;
		mServiceName = serviceName;
		mServiceType = serviceType;
		mNsdManager = (NsdManager)context.getSystemService(Context.NSD_SERVICE);
	}

	public void registerService(int port)
	{
		NsdServiceInfo serviceInfo = new NsdServiceInfo();
		serviceInfo.setPort(port);
		serviceInfo.setServiceName(mServiceName);
		serviceInfo.setServiceType(mServiceType);

		initializeRegistrationListener();
		mNsdManager.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, mRegistrationListener);
	}

	public void discoverServices()
	{
		initializeResolveListener();
		initializeDiscoveryListener();
		mNsdManager.discoverServices(mServiceType, NsdManager.PROTOCOL_DNS_SD, mDiscoveryListener);
	}

	public void stopService()
	{
		if (mRegistrationListener != null)
		{
			mNsdManager.unregisterService(mRegistrationListener);
			mRegistrationListener = null;
		}

		if (mDiscoveryListener != null)
		{
			mNsdManager.stopServiceDiscovery(mDiscoveryListener);
			mDiscoveryListener = null;
		}
	}

	public void initializeDiscoveryListener() {
		mDiscoveryListener = new NsdManager.DiscoveryListener() {

			@Override
			public void onDiscoveryStarted(String regType) {
				Log.d(TAG, "Service discovery started");
			}

			@Override
			public void onServiceFound(NsdServiceInfo service) {
				Log.d(TAG, "Service discovery success" + service);
				if (!service.getServiceType().equals(mServiceType)) {
					Log.d(TAG, "Unknown Service Type: " + service.getServiceType());
				} else if (service.getServiceName().equals(mServiceName)) {
					Log.d(TAG, "Same machine: " + mServiceName);
				} else if (service.getServiceName().contains(mServiceName)){
					mNsdManager.resolveService(service, mResolveListener);
				}
			}

			@Override
			public void onServiceLost(NsdServiceInfo service) {
				Log.e(TAG, "service lost" + service);
				if (mServiceInfo == service) {
					mServiceInfo = null;
				}
			}

			@Override
			public void onDiscoveryStopped(String serviceType) {
				Log.i(TAG, "Discovery stopped: " + serviceType);
			}

			@Override
			public void onStartDiscoveryFailed(String serviceType, int errorCode) {
				Log.e(TAG, "Discovery failed: Error code:" + errorCode);
				mNsdManager.stopServiceDiscovery(this);
			}

			@Override
			public void onStopDiscoveryFailed(String serviceType, int errorCode) {
				Log.e(TAG, "Discovery failed: Error code:" + errorCode);
				mNsdManager.stopServiceDiscovery(this);
			}
		};
	}

	public void initializeResolveListener() {
        mResolveListener = new NsdManager.ResolveListener() {

            @Override
            public void onResolveFailed(NsdServiceInfo serviceInfo, int errorCode) {
                Log.e(TAG, "Resolve failed" + errorCode);
            }

            @Override
            public void onServiceResolved(NsdServiceInfo serviceInfo) {
                Log.e(TAG, "Resolve Succeeded. " + serviceInfo);

                if (serviceInfo.getServiceName().equals(mServiceName)) {
                    Log.d(TAG, "Same IP.");
                    return;
                }
                mServiceInfo = serviceInfo;
            }
        };
    }

	public void initializeRegistrationListener() {
		mRegistrationListener = new NsdManager.RegistrationListener() {

			@Override
			public void onServiceRegistered(NsdServiceInfo serviceInfo) {
				mServiceName = serviceInfo.getServiceName();
				mServiceInfo = serviceInfo;
			}

			@Override
			public void onRegistrationFailed(NsdServiceInfo serviceInfo, int errorCode) {
			}

			@Override
			public void onServiceUnregistered(NsdServiceInfo serviceInfo) {
			}

			@Override
			public void onUnregistrationFailed(NsdServiceInfo serviceInfo, int errorCode) {
			}

		};
	}
}