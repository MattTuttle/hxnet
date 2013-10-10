/*
 * Following is largely based on ofxUDPManager of ofxNetwork.
 * ofxNetwork is an addon of openframeworks(http://www.openframeworks.cc/)
 * Pulled from hxudp project. Thanks to Andy Li!
 */


#include <cerrno>
#include <string>
#include <sstream>
#include <wchar.h>
#include <stdio.h>

#ifndef TARGET_WIN32

	//unix includes - works for osx should be same for *nix
	#include <ctype.h>
	#include <netdb.h>
	#include <fcntl.h>
	#include <errno.h>
	#include <unistd.h>
	#include <string.h>
	#include <arpa/inet.h>
	#include <netinet/in.h>
	#include <sys/types.h>
	#include <sys/socket.h>
	#include <sys/time.h>
	#include <sys/ioctl.h>

    //#ifdef TARGET_LINUX
        // linux needs this:
        #include <netinet/tcp.h>		/* for TCP_MAXSEG value */
    //#endif


	#define SO_MAX_MSG_SIZE TCP_MAXSEG
	#define INVALID_SOCKET -1
	#define SOCKET_ERROR -1
	#define FAR

#else

	#ifndef WIN32_LEAN_AND_MEAN
	#define WIN32_LEAN_AND_MEAN
	#endif

	//windows includes
	#include <winsock2.h>
	#include <ws2tcpip.h>		// TCP/IP annex needed for multicasting

	#define ENOTCONN        WSAENOTCONN
	#define EWOULDBLOCK     WSAEWOULDBLOCK
	#define ENOBUFS         WSAENOBUFS
	#define ECONNRESET      WSAECONNRESET
	#define ESHUTDOWN       WSAESHUTDOWN
	#define EAFNOSUPPORT    WSAEAFNOSUPPORT
	#define EPROTONOSUPPORT WSAEPROTONOSUPPORT
	#define EINPROGRESS     WSAEINPROGRESS
	#define EISCONN         WSAEISCONN
	#define ENOTSOCK        WSAENOTSOCK
	#define EOPNOTSUPP      WSAEOPNOTSUPP
	#define ETIMEDOUT       WSAETIMEDOUT
	#define EADDRNOTAVAIL   WSAEADDRNOTAVAIL
	#define ECONNREFUSED    WSAECONNREFUSED
	#define ENETUNREACH     WSAENETUNREACH
	#define EADDRINUSE      WSAEADDRINUSE
	#define EADDRINUSE      WSAEADDRINUSE
	#define EALREADY        WSAEALREADY
	#define ENOPROTOOPT     WSAENOPROTOOPT
	#define EMSGSIZE        WSAEMSGSIZE
	#define ECONNABORTED    WSAECONNABORTED
#endif

/// Socket constants.
#define SOCKET_TIMEOUT			SOCKET_ERROR - 1
#define NO_TIMEOUT				0xFFFF
#define OF_UDP_DEFAULT_TIMEOUT	NO_TIMEOUT

#include "UdpSocket.h"

using namespace std;

template < class T >
string ofToString(const T& value){
	ostringstream out;
	out << value;
	return out.str();
}

string ofxNetworkCheckError(){
	#ifdef TARGET_WIN32
		int	err	= WSAGetLastError();
	#else
		int err = errno;
	#endif
	switch(err){
	case 0:
		break;
	case EBADF:
		return "EBADF: invalid socket";
	case ECONNRESET:
		return "ECONNRESET: connection closed by peer";
	case EINTR:
		return "EINTR: receive interrupted by a signal, before any data available";
	case ENOTCONN:
		return "ENOTCONN: trying to receive before establishing a connection";
	case ENOTSOCK:
		return "ENOTSOCK: socket argument is not a socket";
	case EOPNOTSUPP:
		return "EOPNOTSUPP: specified flags not valid for this socket";
	case ETIMEDOUT:
		return "ETIMEDOUT: timeout";
	case EIO:
		return "EIO: io error";
	case ENOBUFS:
		return "ENOBUFS: insufficient buffers to complete the operation";
	case ENOMEM:
		return "ENOMEM: insufficient memory to complete the request";
	case EADDRNOTAVAIL:
		return "EADDRNOTAVAIL: the specified address is not available on the remote machine";
	case EAFNOSUPPORT:
		return "EAFNOSUPPORT: the namespace of the addr is not supported by this socket";
	case EISCONN:
		return "EISCONN: the socket is already connected";
	case ECONNREFUSED:
		return "ECONNREFUSED: the server has actively refused to establish the connection";
	case ENETUNREACH:
		return "ENETUNREACH: the network of the given addr isn't reachable from this host";
	case EADDRINUSE:
		return "EADDRINUSE: the socket address of the given addr is already in use";
	case EINPROGRESS:
		//return "EINPROGRESS: the socket is non-blocking and the connection could not be established immediately";
		break;
	case EALREADY:
		return "EALREADY: the socket is non-blocking and already has a pending connection in progress";
	case ENOPROTOOPT:
		return "ENOPROTOOPT: The optname doesn't make sense for the given level.";
	case EPROTONOSUPPORT:
		return "EPROTONOSUPPORT: The protocol or style is not supported by the namespace specified.";
	case EMFILE:
		return "EMFILE: The process already has too many file descriptors open.";
	case ENFILE:
		return "ENFILE: The system already has too many file descriptors open.";
	case EACCES:
		return "EACCES: The process does not have the privilege to create a socket of the specified style or protocol.";
	case EMSGSIZE:
		return "EMSGSIZE: The socket type requires that the message be sent atomically, but the message is too large for this to be possible.";
	case EPIPE:
		return "EPIPE: This socket was connected but the connection is now broken.";
	case EAGAIN:
		//ofLog(OF_LOG_VERBOSE,"ofxNetwork:"+file+": " +line+" EAGAIN: try again");
		break;
#ifdef TARGET_WIN32
	case WSAEWOULDBLOCK:
		// represents "resource temporarily unavailable", can be ignored
		break;
#endif
	default:
		return " unknown error: " + ofToString(err) + " see errno.h for description of the error";
	}

	return "OK";
}



//////////////////////////////////////////////////////////////////////////////////////
// Original author: ???????? we think Christian Naglhofer
// Crossplatform port by: Theodore Watson May 2007 - update Jan 2008
// Changes: Mac (and should be nix) equivilant functions and data types for
// win32 calls, as well as non blocking option SetNonBlocking(bool nonBlocking);
//
//////////////////////////////////////////////////////////////////////////////////////

namespace hxnet
{

	//constructor
	UdpSocket::UdpSocket()
	{
		// was winsock initialized?
		#ifdef TARGET_WIN32
			if (!m_bWinsockInit)
			{
				unsigned short vr;
				WSADATA	wsaData;
				vr=	MAKEWORD(2,	2);
				WSAStartup(vr, &wsaData);
				m_bWinsockInit=	true;
			}
		#endif

        m_hSocket           = INVALID_SOCKET;
        m_dwTimeoutReceive  = OF_UDP_DEFAULT_TIMEOUT;
        m_iListenPort       = -1;

        canGetRemoteAddress = false;
        nonBlocking         = true;
	}

	UdpSocket::~UdpSocket()
	{
		if ((m_hSocket) && (m_hSocket != INVALID_SOCKET)) Close();
	}

	/**
	 * Closes an open socket.
	 * NOTE: A	closed socket cannot be	reused again without a call	to "Create()".
	 */
	bool UdpSocket::Close()
	{
		if (m_hSocket == INVALID_SOCKET)
			return(false);

		#ifdef TARGET_WIN32
			if(closesocket(m_hSocket) == SOCKET_ERROR)
		#else
			if(close(m_hSocket) == SOCKET_ERROR)
		#endif
		{
			ofxNetworkCheckError();
			return(false);
		}
		m_hSocket= INVALID_SOCKET;

		return(true);
	}

	bool UdpSocket::Create()
	{
		if (m_hSocket != INVALID_SOCKET)
			return false;

		m_hSocket =	socket(AF_INET,	SOCK_DGRAM,	0);
		bool success = m_hSocket !=	INVALID_SOCKET;
		if (success)
		{
			int unused = true;
			setsockopt(m_hSocket, SOL_SOCKET, SO_REUSEADDR, (char*)&unused, sizeof(unused));
		}
		else
		{
			ofxNetworkCheckError();
		}
		return success;
	}

	bool UdpSocket::Connect(const char *pHost, unsigned short usPort)
	{
		//	sockaddr_in	addr_in= {0};
		memset(&saClient, 0, sizeof(sockaddr_in));
		struct hostent *he;

		if (m_hSocket == INVALID_SOCKET) return(false);

		if ((he	= gethostbyname(pHost))	== NULL)
			return(false);

		saClient.sin_family= AF_INET; // host byte order
		saClient.sin_port  = htons(usPort);	// short, network byte order
		//	saClient.sin_addr  = *((struct g_addr *)he->h_addr_list);
		//cout << inet_addr( pHost ) << endl;
		//saClient.sin_addr.s_addr= inet_addr( pHost );
		//saClient.sin_addr = *((struct in_addr *)he->h_addr);
		memcpy((char *) &saClient.sin_addr.s_addr,
			 he->h_addr_list[0], he->h_length);

	    memset(&(saClient.sin_zero), '\0', 8);  // zero the rest of the struct


		return true;
	}

	bool UdpSocket::ConnectMcast(const char *pMcast, unsigned short usPort)
	{
		// associate the source socket's address with the socket
		if (!Bind(usPort))
		{
			#ifdef _DEBUG
			printf("Binding socket failed! Error: %d", WSAGetLastError());
			#endif
			return false;
		}

		// set ttl to default
		if (!SetTTL(1))
		{
			#ifdef _DEBUG
			printf("SetTTL failed. Continue anyway. Error: %d", WSAGetLastError());
			#endif
		}

		if (!Connect(pMcast, usPort))
		{
			#ifdef _DEBUG
			printf("Connecting socket failed! Error: %d", WSAGetLastError ());
			#endif
			return false;
		}

		// multicast connect successful
		return true;
	}

	bool UdpSocket::Bind(unsigned short port)
	{
		saServer.sin_family	= AF_INET;
		saServer.sin_addr.s_addr = INADDR_ANY;
		//Port MUST	be in Network Byte Order
		saServer.sin_port =	htons(port);

		int	ret	= bind(m_hSocket, (struct sockaddr*)&saServer, sizeof(struct sockaddr));
		if (ret == -1)  ofxNetworkCheckError();

		return (ret	== 0);
	}

	bool UdpSocket::BindMcast(const char *pMcast, unsigned short usPort)
	{
		// bind to port
		if (!Bind(usPort))
		{
			//ofLog(OF_LOG_WARNING, "can't bind to port \n");
			return false;
		}

		// join the multicast group
		struct ip_mreq mreq;
		mreq.imr_multiaddr.s_addr = inet_addr(pMcast);
		mreq.imr_interface.s_addr = INADDR_ANY;

		if (setsockopt(m_hSocket, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char FAR*) &mreq, sizeof (mreq)) == SOCKET_ERROR)
		{
			ofxNetworkCheckError();
			return false;
		}

		// multicast bind successful
		return true;
	}

	/**
	 * Return values:
	 * SOCKET_TIMEOUT indicates timeout
	 * SOCKET_ERROR in	case of	a problem.
	 */
	int  UdpSocket::Send(const char* pBuff, const int iSize)
	{
		if (m_hSocket == INVALID_SOCKET) return SOCKET_ERROR;

		/*if (m_dwTimeoutSend	!= NO_TIMEOUT)
		{
			fd_set fd;
			FD_ZERO(&fd);
			FD_SET(m_hSocket, &fd);
			timeval	tv=	{m_dwTimeoutSend, 0};
			if(select(m_hSocket+1,NULL,&fd,NULL,&tv)== 0)
			{
				return(SOCKET_TIMEOUT);
			}
		}*/

		int ret = sendto(m_hSocket, (char*)pBuff, iSize, 0, (sockaddr *)&saClient, sizeof(sockaddr));
		if(ret==-1) ofxNetworkCheckError();
		return ret;
		//	return(send(m_hSocket, pBuff, iSize, 0));
	}

	/**
	 * all data will be sent guaranteed.
	 * Return values:
	 * SOCKET_TIMEOUT indicates timeout
	 * SOCKET_ERROR in	case of	a problem.
	 */
	int  UdpSocket::SendAll(const char* pBuff, const int iSize)
	{
		if (m_hSocket == INVALID_SOCKET) return(SOCKET_ERROR);

		if (m_dwTimeoutSend	!= NO_TIMEOUT)
		{
			fd_set fd;
			FD_ZERO(&fd);
			FD_SET(m_hSocket, &fd);
			timeval	tv=	{m_dwTimeoutSend, 0};
			if(select(m_hSocket+1,NULL,&fd,NULL,&tv)== 0)
			{
				ofxNetworkCheckError();
				return(SOCKET_TIMEOUT);
			}
		}


		int	total= 0;
		int	bytesleft =	iSize;
		int	n=0;

		while (total < iSize)
		{
			n =	sendto(m_hSocket, (char*)pBuff,	iSize, 0, (sockaddr *)&saClient, sizeof(sockaddr));
			if (n == -1)
				{
					ofxNetworkCheckError();
					break;
				}
			total += n;
			bytesleft -=n;
		}

		return n==-1?SOCKET_ERROR:total;
	}

	/**
	 * Return values:
	 * SOCKET_TIMEOUT indicates timeout
	 * SOCKET_ERROR in	case of	a problem.
	 */
	int  UdpSocket::Receive(char* pBuff, const int iSize)
	{
		if (m_hSocket == INVALID_SOCKET)
		{
			return SOCKET_ERROR;
		}

		/*if (m_dwTimeoutSend	!= NO_TIMEOUT)
		{
			fd_set fd;
			FD_ZERO(&fd);
			FD_SET(m_hSocket, &fd);
			timeval	tv=	{m_dwTimeoutSend, 0};
			if(select(m_hSocket+1,&fd,NULL,NULL,&tv)== 0)
			{
				return(SOCKET_TIMEOUT);
			}
		}*/

		#ifndef TARGET_WIN32
			socklen_t nLen = sizeof(sockaddr);
		#else
			int	nLen = sizeof(sockaddr);
		#endif

		int	ret = 0;

		memset(pBuff, 0, iSize);
		ret = recvfrom(m_hSocket, pBuff, iSize, 0, (sockaddr *)&saClient, &nLen);

		if (ret	> 0)
		{
			// printf("\nreceived from: %s\n",	inet_ntoa((in_addr)saClient.sin_addr));
			canGetRemoteAddress = true;
		}
		else
		{
			ofxNetworkCheckError();
			// printf("\nreceived from: ????\n");
			canGetRemoteAddress = false;
		}

		return ret;
		//	return(recvfrom(m_hSocket, pBuff, iSize, 0));
	}

	void UdpSocket::SetTimeoutSend(int timeoutInSeconds)
	{
		m_dwTimeoutSend= timeoutInSeconds;
	}

	void UdpSocket::SetTimeoutReceive(int timeoutInSeconds){
		m_dwTimeoutReceive=	timeoutInSeconds;
	}

	int  UdpSocket::GetTimeoutSend()
	{
		return m_dwTimeoutSend;
	}

	int  UdpSocket::GetTimeoutReceive()
	{
		return m_dwTimeoutReceive;
	}

	/**
	 * returns the IP of last received packet
	 */
	bool UdpSocket::GetRemoteAddr(char* address, int *port)
	{
		if (m_hSocket == INVALID_SOCKET) return false;
		if (canGetRemoteAddress == false) return false;

		inet_ntop(AF_INET, &(saClient.sin_addr), address, INET_ADDRSTRLEN);
		*port = saClient.sin_port;
		return true;
	}

	bool UdpSocket::SetReceiveBufferSize(int sizeInByte)
	{
		if (m_hSocket == INVALID_SOCKET) return(false);

		if ( setsockopt(m_hSocket, SOL_SOCKET, SO_RCVBUF, (char*)&sizeInByte, sizeof(sizeInByte)) == 0){
			return true;
		}else{
			ofxNetworkCheckError();
			return false;
		}
	}

	bool UdpSocket::SetSendBufferSize(int sizeInByte)
	{
		if (m_hSocket == INVALID_SOCKET) return(false);

		if ( setsockopt(m_hSocket, SOL_SOCKET, SO_SNDBUF, (char*)&sizeInByte, sizeof(sizeInByte)) == 0){
			return true;
		}else{
			ofxNetworkCheckError();
			return false;
		}
	}

	int  UdpSocket::GetReceiveBufferSize()
	{
		if (m_hSocket == INVALID_SOCKET) return(false);

		int	sizeBuffer=0;

		#ifndef TARGET_WIN32
			socklen_t size = sizeof(int);
		#else
			int size = sizeof(int);
		#endif

		int ret = getsockopt(m_hSocket, SOL_SOCKET, SO_RCVBUF, (char*)&sizeBuffer, &size);
		if(ret==-1) ofxNetworkCheckError();
		return sizeBuffer;
	}

	int  UdpSocket::GetSendBufferSize()
	{
		if (m_hSocket == INVALID_SOCKET) return(false);

		int	sizeBuffer=0;

		#ifndef TARGET_WIN32
			socklen_t size = sizeof(int);
		#else
			int size = sizeof(int);
		#endif

		int ret = getsockopt(m_hSocket, SOL_SOCKET, SO_SNDBUF, (char*)&sizeBuffer, &size);
		if(ret==-1) ofxNetworkCheckError();

		return sizeBuffer;
	}

	bool UdpSocket::SetReuseAddress(bool allowReuse)
	{
		if (m_hSocket == INVALID_SOCKET) return(false);

		int	on;
		if (allowReuse)	on=1;
		else			on=0;

		if ( setsockopt(m_hSocket, SOL_SOCKET, SO_REUSEADDR, (char*)&on, sizeof(on)) ==	0){
			return true;
		}else{
			ofxNetworkCheckError();
			return false;
		}
	}

	bool UdpSocket::SetEnableBroadcast(bool enableBroadcast)
	{
		int	on;
		if (enableBroadcast)	on=1;
		else					on=0;

		if ( setsockopt(m_hSocket, SOL_SOCKET, SO_BROADCAST, (char*)&on, sizeof(on)) ==	0){
			return true;
		}else{
			ofxNetworkCheckError();
			return false;
		}
	}

	/**
	 * Choose to set nonBLocking - default mode is to block
	 */
	bool UdpSocket::SetNonBlocking(bool useNonBlocking)
	{
		if (m_hSocket == INVALID_SOCKET) return false;
		nonBlocking		= useNonBlocking;

		#ifdef TARGET_WIN32
			unsigned long arg = nonBlocking;
			int retVal = ioctlsocket(m_hSocket,FIONBIO,&arg);
		#else
			// int arg			= nonBlocking;
			// int retVal = ioctl(m_hSocket,FIONBIO,&arg);
			int flags = fcntl(m_hSocket, F_GETFL, 0);
			int retVal = fcntl(m_hSocket, F_SETFL, flags | O_NONBLOCK);
		#endif

		bool ret = (retVal >= 0);
		if (!ret) ofxNetworkCheckError();
		return ret;
	}

	int  UdpSocket::GetMaxMsgSize()
	{
		if (m_hSocket == INVALID_SOCKET) return false;

		int	sizeBuffer=0;

		#ifndef TARGET_WIN32
			socklen_t size = sizeof(int);
		#else
			int size = sizeof(int);
		#endif

		int ret = getsockopt(m_hSocket, SOL_SOCKET, SO_MAX_MSG_SIZE, (char*)&sizeBuffer, &size);
		if(ret==-1) ofxNetworkCheckError();
		return sizeBuffer;
	}

	/**
	 * returns -1 on failure
	 */
	int  UdpSocket::GetTTL()
	{
		if (m_hSocket == INVALID_SOCKET) return(false);

		int nTTL;

		#ifndef TARGET_WIN32
			socklen_t nSize = sizeof(int);
		#else
			int nSize = sizeof(int);
		#endif

		if (getsockopt(m_hSocket, IPPROTO_IP, IP_MULTICAST_TTL, (char FAR *) &nTTL, &nSize) == SOCKET_ERROR)
		{
			#ifdef _DEBUG
			printf("getsockopt failed! Error: %d", WSAGetLastError());
			#endif
			ofxNetworkCheckError();
			return -1;
		}

		return nTTL;
	}

	bool UdpSocket::SetTTL(int nTTL)
	{
		if (m_hSocket == INVALID_SOCKET) return(false);

		// Set the Time-to-Live of the multicast.
		if (setsockopt(m_hSocket, IPPROTO_IP, IP_MULTICAST_TTL, (char FAR *)&nTTL, sizeof (int)) == SOCKET_ERROR)
		{
			#ifdef _DEBUG
			printf("setsockopt failed! Error: %d", WSAGetLastError());
			#endif
			ofxNetworkCheckError();
			return false;
		}

		return true;
	}


	bool UdpSocket::m_bWinsockInit= false;

} // namespace hxnet

/*
//--------------------------------------------------------------------------------
bool UdpSocket::GetInetAddr(LPINETADDR	pInetAddr)
{
if (m_hSocket == INVALID_SOCKET) return(false);

int	iSize= sizeof(sockaddr);
return(getsockname(m_hSocket, (sockaddr *)pInetAddr, &iSize) !=	SOCKET_ERROR);
}
*/

