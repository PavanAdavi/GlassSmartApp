//
//  CommandParser.swift
//  AiraSmartApp
//
//  Created by Adavi, Pavan on 11/5/15.
//  Copyright © 2015 Aira. All rights reserved.
//

import Foundation
import UIKit

/*
Service command definitions
"SST###"
*/

/**
List of commands

- ServiceInitiate:  Initiate connect - Show phone connected
- ServiceStart:     Start phone call
- ServiceCancelled: Cancel service
- ServiceEnded:     End phone call and service
- Unknown:          Unknow command string
*/
enum CommandType : String {
    case ServiceInitiate    = "INF"
    case ServiceStart       = "SST"
    case ServiceCancelled   = "SCD"
    case ServiceEnded       = "SED"
    case ServiceUnknown     = "UNKNOWN"
    
}



class CommandParser {

    private var rawMessage : String = ""
    private var messageOptions : [String] = []
    var commandType : CommandType = .ServiceUnknown
    
    
    init(messageString: String)
    {
        self.rawMessage = messageString
        self.parseCommand();
    }
    
    func parseCommand() {
        
        if(rawMessage.isEmpty) {
            // Default return
            return
        }
        
         messageOptions = rawMessage.componentsSeparatedByString("###")
     
        if(messageOptions.count == 0) {
            return
        }
        
        // TODO : Add additional validations for input message like call number is present etc
        // More parsing logic goes here.
        
        switch(messageOptions[0]) {
            case CommandType.ServiceInitiate.rawValue :
                // Check if the message has all valid options
                if(isValidOptions(.ServiceInitiate)) {
                    commandType = .ServiceInitiate
                }
                
                break
            case CommandType.ServiceStart.rawValue :
                if(isValidOptions(.ServiceStart)) {
                    commandType = .ServiceStart
                }
                
                break
            case CommandType.ServiceCancelled.rawValue :
                commandType = .ServiceCancelled
                break
            case CommandType.ServiceEnded.rawValue :
                commandType = .ServiceEnded
                break
            default :
                break
        }
        
    }

    func isValidOptions(messageType : CommandType) -> Bool {
        
        var validOptions = false
        
        // vaidate option here
        // Fuzzy logic for now.
        // TODO: Add email and other validations

        switch (messageType) {
        
            case CommandType.ServiceInitiate :
                
                if (messageOptions.count == 2) {
                    validOptions = true
                }
                break
            case CommandType.ServiceStart :
                
                  if (messageOptions.count == 10) {
                    validOptions = true
                }

                break
            case CommandType.ServiceCancelled :
 
                if (messageOptions.count == 3) {
                    validOptions = true
                }

                break
            case CommandType.ServiceEnded :
                
                if (messageOptions.count == 4) {
                    validOptions = true
                }

                break

            default :
                break
        }
        
       return validOptions
    }
    
    /**
     Execute a things for each service command
     
     - returns: true if service is started
     */
    func executeCommand() -> Bool {
        print("Executing command \(commandType.rawValue)")
        
        switch(commandType) {
        case CommandType.ServiceInitiate :
            
            break
        case CommandType.ServiceStart :
            callNumber(messageOptions[7])
            break
        case CommandType.ServiceCancelled :
            
            break
        case CommandType.ServiceEnded :
            
            break
        default :
            break

        }
        
        return false
    
    }
    /**
     Initiates a phone call
     
     - parameter phoneNumber: phone number to call
     */
    private func callNumber(phoneNumber:String) {
        if let phoneCallURL:NSURL = NSURL(string: "tel://\(phoneNumber)") {
            let application:UIApplication = UIApplication.sharedApplication()
            if (application.canOpenURL(phoneCallURL)) {
                application.openURL(phoneCallURL);
            }
        }
    }

}