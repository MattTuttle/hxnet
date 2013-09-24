#ifndef __UDPSOCKET_H__
#define __UDPSOCKET_H__

namespace hxnet
{

	class UdpSocket
	{
	public:
		UdpSocket();
		virtual ~UdpSocket();

		/**
		 * Closes an open socket.
		 * NOTE: A	closed socket cannot be	reused again without a call	to "Create()".
		 */
		bool Close();
		bool Create();
		bool Connect(const char *pHost, unsigned short usPort);
		bool ConnectMcast(const char *pMcast, unsigned short usPort);
		bool Bind(unsigned short usPort);
		bool BindMcast(const char *pMcast, unsigned short usPort);
		/**
		 * Return values:
		 * SOCKET_TIMEOUT indicates timeout
		 * SOCKET_ERROR in	case of	a problem.
		 */
		int  Send(const char* pBuff, const int iSize);
		/**
		 * all data will be sent guaranteed.
		 * Return values:
		 * SOCKET_TIMEOUT indicates timeout
		 * SOCKET_ERROR in	case of	a problem.
		 */
		int  SendAll(const char* pBuff, const int iSize);
		/**
		 * Return values:
		 * SOCKET_TIMEOUT indicates timeout
		 * SOCKET_ERROR in	case of	a problem.
		 */
		int  Receive(char* pBuff, const int iSize);
		void SetTimeoutSend(int timeoutInSeconds);
		void SetTimeoutReceive(int timeoutInSeconds);
		int  GetTimeoutSend();
		int  GetTimeoutReceive();
		/**
		 * returns the IP of last received packet
		 */
		bool GetRemoteAddr(char* address, int* port);
		bool SetReceiveBufferSize(int sizeInByte);
		bool SetSendBufferSize(int sizeInByte);
		int  GetReceiveBufferSize();
		int  GetSendBufferSize();
		bool SetReuseAddress(bool allowReuse);
		bool SetEnableBroadcast(bool enableBroadcast);
		/**
		 * Choose to set nonBLocking - default mode is to block
		 */
		bool SetNonBlocking(bool useNonBlocking);
		int  GetMaxMsgSize();

		/**
		 * returns -1 on failure
		 */
		int  GetTTL();
		bool SetTTL(int nTTL);

	protected:
		int m_iListenPort;

		#ifdef TARGET_WIN32
			SOCKET m_hSocket;
		#else
			int m_hSocket;
		#endif


		unsigned long m_dwTimeoutReceive;
		unsigned long m_dwTimeoutSend;

		bool nonBlocking;

		struct sockaddr_in saServer;
		struct sockaddr_in saClient;

		static bool m_bWinsockInit;
		bool canGetRemoteAddress;

	};

}

#endif
