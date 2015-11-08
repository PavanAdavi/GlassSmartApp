//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
/*
On TCP Connect
Glass to Phone : INF###<user email>###
Phone Action : Show Connected.

Service Started
Glass to Phone : SST###<user email>###<first name>###<last name>###<agent email>###<agent first name>###<agent last name>###<agent phone num>###<serviceid>###
Phone Action : Make call to agent phone number. Bring app to foreground.
Service Cancelled
Glass to Phone : SCD###<user email>###<serviceid>###
Phone Action : Show Phone Connected.
Service Ended
Glass to Phone : SED##<user email>###<serviceid>###<agent phone num>###
Phone Action : Disconnected the phone call, show disconnected animation. Bring back to home screen.

*/

enum CommandType : String {
    case ServiceInitiate = "INF"
    case ServiceStart = "SST"
    case ServiceCancelled = "SCD"
    case ServiceEnded = "SED"
    case ServiceUnknown
    
}
 var commandType : CommandType = .ServiceUnknown
var messageOptions : [String] = []

func parseCommand(rawMessage: String) {
    
    if(rawMessage.isEmpty) {
        // Default return
        return
    }
    
    messageOptions = rawMessage.componentsSeparatedByString("###")
    
    if(messageOptions.count == 0) {
        return
    }
    
    switch(messageOptions[0]) {
        case CommandType.ServiceInitiate.rawValue :
            commandType = .ServiceInitiate
            break
        case CommandType.ServiceStart.rawValue :
            if(isValidOptions(.ServiceInitiate)) {
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
    
    print(messageOptions)
    switch (messageType) {
        
    case CommandType.ServiceInitiate :
        
        if (messageOptions.count == 2) {
            validOptions = true
        }
        break
    case CommandType.ServiceStart :
        
        if (messageOptions.count == 8) {
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


// Test 1
parseCommand("INF###<user email>###\n\r")

print(commandType)


// Test 2
//parseCommand("SST###<user email>###<first name>###<last name>###<agent email>###<agent first name>###<agent last name>###<agent phone num>###<serviceid>###\n\r")
//
//print(commandType)
//
//
//parseCommand("SCD###<user email>###<serviceid>###\n\r")
//
//print(commandType)
//








