//
//  ViewController.swift
//  AiraSmartApp
//
//  Created by Adavi, Pavan on 11/3/15.
//  Copyright © 2015 Aira. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

var isRunning = false

class ViewController: UIViewController {

    @IBOutlet weak var tvLogMessages: UITextView!
    @IBOutlet weak var btnStartServer: UIButton!
    @IBOutlet weak var lblLogLabel: UILabel!
    
    var listenSocket : GCDAsyncSocket!
    var socketQueue : dispatch_queue_t!
    var connectedSockets : NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        socketQueue = dispatch_queue_create("socketQueue", DISPATCH_QUEUE_CONCURRENT)
        listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)
        tvLogMessages.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnStartServerClicked(sender: AnyObject) {
        
        // Start the server if its not running
        if(!isRunning) {
            let port:UInt16 = 8080     // TODO : get this from UI ?
            
            do {
                try listenSocket.acceptOnPort(port)
            } catch{
             
                print("Error unable to start server on port:",error)
                lblLogLabel.text = "Unable to start server. Try again!!"
                return
            }
            // If we are here means server is listening
            appendToLog ("server listening for clients....." )
            
            lblLogLabel.text = "Started tcp server..!!\nServer Address :\( getIFAddresses()) \nPORT :\(listenSocket.localPort)"
            btnStartServer.setTitle("Stop Server", forState: UIControlState.Normal)
            isRunning = true
            
        } else {
            
            // if there are any pending then disconnect gracefully
            listenSocket.disconnectAfterReadingAndWriting()
            
            //stop any pending connections
            synced(connectedSockets) {
                for socket in self.connectedSockets {
                    socket.disconnectAfterReadingAndWriting()
                }
            }
            lblLogLabel.text = "Stopped server ...!!\nClick start to restart server"
            btnStartServer.setTitle("Start Server", forState: UIControlState.Normal)
            isRunning = false
        }
    }

    func appendToLog(message : String)
    {
        print(message)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.tvLogMessages.text =  self.tvLogMessages.text.stringByAppendingString("\n\(message)")
        }
    }
    
    
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
        
        newSocket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: 5, tag: 1)
    }
    
    func socket(socket : GCDAsyncSocket, didReadData data:NSData, withTag tag:UInt16)
    {
        let response = NSString(data: data, encoding: NSUTF8StringEncoding)
        
        appendToLog("Received Response:Tag: \(tag) : \(response!) ")
        // TODO: check the message and act on it for now just echo back the message
        
        socket.writeData(data, withTimeout: -1, tag: 1)
        socket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: 5, tag: 1)
        
    }
    
    func socket(socket : GCDAsyncSocket, socketDidDisconnect error:NSError)
    {
        appendToLog ("Disconneted from host : \(socket.connectedHost) , \(socket.connectedPort)" )
    }
    
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    // Get all addresses of the phone. 
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory
                
                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                                if let address = String.fromCString(hostname) {
                                    addresses.append(address)
                                }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return addresses
    }
}

