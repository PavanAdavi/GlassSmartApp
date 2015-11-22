//
//  TcpServer.swift
//  AiraSmartApp
//
//  Created by Adavi, Pavan on 11/5/15.
//  Copyright © 2015 Aira. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

let TCPServerReceivedMessageNotification: String = "TCPServerReceivedMessageNotification"

enum TcpServerError : ErrorType {
    case WifiOrHotspotNotEnabled
    case StartServerFailed
}

class TcpServer : NSObject,  GCDAsyncSocketDelegate {
    
    private var listenSocket : GCDAsyncSocket!
    private var socketQueue : dispatch_queue_t!
    private var connectedSockets : NSMutableArray = []
    private var isRunning = false
    private var serverAddress:String = ""
    private let port:UInt16 = 8080
    
    override init() {
        super.init()
        self.socketQueue = dispatch_queue_create("socketQueue", DISPATCH_QUEUE_CONCURRENT)
        self.listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)

    }
    
    var hostAddress :String {
        get {
            return (" tcp://\(serverAddress):\(port)")
        }
    }
    
    /**
     Starts a tcp server on wifi or hotspot
     
     - throws: NSerror if failed
     - returns: true if server is started
     */
    
    func startServer() throws -> Bool {
        
        // Start the server if its not running
        if(!isRunning) {
            
                // TODO : get this from UI ?
            
            do {
                
                if let ipaddress = getWiFiAddress() {
                    self.serverAddress = ipaddress
                    try listenSocket.acceptOnPort(port)
                } else {
                    appendToLog("No hotspot or wifi address found Cannot start server as ")
                    throw TcpServerError.WifiOrHotspotNotEnabled
                }
                
            } catch{
                
                print("Error unable to start server on port:",error)
                throw error
            }
            
            // If we are here means server is listening
            appendToLog ("server listening for clients....." )
            isRunning = true

        }
        return true
    }
    
    /**
     Stops the tcp server if running
     
     - returns: true if server is stopped
     */
    func stopServer() -> Bool {
        
        if(isRunning) {
            // if there are any pending then disconnect gracefully
            listenSocket.disconnectAfterReadingAndWriting()
            //stop any pending connections
            synced(connectedSockets) {
                for socket in self.connectedSockets {
                    socket.disconnectAfterReadingAndWriting()
                }
            }
            isRunning = false
            return true
        }
        return false
    }
    
    /**
     Delegate called when a new socket is opened
     
    */
    func socket(socket : GCDAsyncSocket, didAcceptNewSocket newSocket:GCDAsyncSocket)
    {
        synced(connectedSockets)
            {
                self.connectedSockets.addObject(newSocket)
        }
        
        appendToLog ("Accepting new client from host :\(newSocket.connectedHost), \(newSocket.connectedPort)")
        
        // Send welcome message
        let welcomeMsg = "Welcome to the AiraSmartApp\r\n";
        let welcomeData:NSData = welcomeMsg.dataUsingEncoding(NSUTF8StringEncoding)!
        newSocket.writeData(welcomeData, withTimeout: -1, tag: 0)
        // Start reading
        newSocket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 1)
    }
    
    func socket(socket: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        let response = NSString(data: data, encoding: NSUTF8StringEncoding)
        
        appendToLog("Received Response:Tag: \(tag) : \(response!) ")
        
        // Post notification with the response.
        NSNotificationCenter.defaultCenter().postNotificationName(TCPServerReceivedMessageNotification, object: response)
        // Echo back the command for now.
        socket.writeData(data, withTimeout: -1, tag: 1)
        // Start read loop again.
        socket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 1)

    }
    
    
    /**
     Called when socket is disconnected
     
     - parameter socket: disconnected socket
     - parameter error:  NSError if failed to disconnect
     */
    func socket(socket : GCDAsyncSocket, socketDidDisconnect error:NSError)
    {
        appendToLog ("Disconneted from host : \(socket.connectedHost) , \(socket.connectedPort)" )
    }
    
    /**
     Thread safe call on an object
     
     - parameter lock:    object to loc
     - parameter closure: code block to execute in lock
     */
    
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    
    func appendToLog(message:String)
    {
        // TODO : Implement a logger
        print(message)
        
    }
    
    
    //
    /**
    Get all addresses of the phone.
    
    - returns: Return IP address of WiFi interface (en0) or hotspot address as a String, or `nil`
    */

    func getWiFiAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let interface = ptr.memory
                
                var tempAddr : String?
                
                // Check for IPv4 or IPv6 interface:
                let addrFamily = interface.ifa_addr.memory.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.memory
                    var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.memory.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, socklen_t(0), NI_NUMERICHOST)
                    tempAddr = String.fromCString(hostname)
                    
                    // Check interface name: WIFI
                    if let name = String.fromCString(interface.ifa_name) where name == "en0" {
                        address = tempAddr
                        self.appendToLog("available WIFI address")
             
                    }
                    // Check interface name: hotspot
                    if let name = String.fromCString(interface.ifa_name) where name == "pdp_ip0" {
                        self.appendToLog("Hotspot enabled..")
                        address = tempAddr
                    }

                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    

}