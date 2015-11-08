//
//  ViewController.swift
//  AiraSmartApp
//
//  Created by Adavi, Pavan on 11/3/15.
//  Copyright © 2015 Aira. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    @IBOutlet weak var tvLogMessages: UITextView!
    @IBOutlet weak var btnStartServer: UIButton!
    @IBOutlet weak var lblLogLabel: UILabel!
    
    let notificationCenter = NSNotificationCenter.defaultCenter()
    let tcpServer = TcpServer()
    private var isServerStarted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tvLogMessages.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        tcpServer.stopServer()
    }
    
    @IBAction func btnStartServerClicked(sender: AnyObject) {
        
        // Start the server if its not running
        
        if(!isServerStarted) {
            do {
                try isServerStarted = tcpServer.startServer()
                if(isServerStarted) {
                    
                    lblLogLabel.text = "Started tcp server..!!\nServer Address : \(tcpServer.hostAddress)"
                    btnStartServer.setTitle("Stop Server", forState: UIControlState.Normal)
                    appendToLog("Waiting for clients....",host: "Server")
                }
                notificationCenter.addObserver(
                    self,
                    selector: "didReceiveCommand:",
                    name:TCPServerReceivedMessageNotification,
                    object: nil
                )
                
            } catch {
                lblLogLabel.text = "Error : Unable to start tcp server. \n\(error) "
            }

        } else {
            tcpServer.stopServer()
            isServerStarted = false
            lblLogLabel.text = "TCP server stopped.\nClick start button to start server."
            btnStartServer.setTitle("Start Server", forState: UIControlState.Normal)
            appendToLog("stopped",host: "Server")
        }
        
    }
    
    func didReceiveCommand(sender : AnyObject) {
        //Create a command parser and execute the command
        
        let message = sender.object as! String
        let commandParser = CommandParser(messageString: message )
        appendToLog(message,host: "Client")
        if(commandParser.commandType == CommandType.ServiceUnknown) {
            // Say something here
            appendToLog("Unknown command..",host: "Server")
        } else {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.appendToLog("Executing command..",host: "Server")
                commandParser.executeCommand()
            }
            
        }
        
    }
    
    func appendToLog(message : String , host: String)
    {
        var logMessage = host
        
        logMessage.appendContentsOf(":\(message)")
        
        print(logMessage)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.tvLogMessages.text =  self.tvLogMessages.text.stringByAppendingString("\n\(logMessage)")
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

