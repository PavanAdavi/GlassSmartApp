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
            print("server listening for clients.....")
        
            lblLogLabel.text = "Started server on  \( listenSocket.localHost):\(listenSocket.localPort)..!!"
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
            lblLogLabel.text = "Stopped server ...!! Click start to restart server"
             btnStartServer.setTitle("Start Server", forState: UIControlState.Normal)
        }
    }

    
    func socket(socket : GCDAsyncSocket, didAcceptNewSocket newSocket:GCDAsyncSocket)
    {
        synced(connectedSockets)
        {
            self.connectedSockets.addObject(newSocket)
        }
        let client = newSocket.connectedHost
        let clientPort = newSocket.connectedPort
        print("Accepting new client from host : \(client) , \(clientPort)" )
        
        // Send welcome message
        let welcomeMsg = "Welcome to the AiraSmartApp\r\n";
        let welcomeData:NSData = welcomeMsg.dataUsingEncoding(NSUTF8StringEncoding)!
        newSocket.writeData(welcomeData, withTimeout: -1, tag: 0)
        
    }
    
    func socket(socket : GCDAsyncSocket, didReadData data:NSData, withTag tag:UInt16)
    {
        let response = NSString(data: data, encoding: NSUTF8StringEncoding)
        print("Received Response",response )
        
        
    }
    
    func socket(socket : GCDAsyncSocket, socketDidDisconnect error:NSError)
    {
        
    }
    
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
}

