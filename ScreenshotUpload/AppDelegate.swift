//
//  AppDelegate.swift
//  ScreenshotUpload
//
//  Created by Jeena on 2014-06-22.
//  Copyright (c) 2014 Jabs Nu. All rights reserved.
//

import Cocoa
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet var window: NSWindow
    @IBOutlet var takeScreenshotButton : NSButton


    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        
        if !self.handledURL(aNotification) {
            
            // Insert code here to initialize your application
            let defaults = NSUserDefaults.standardUserDefaults()
            let fileName = defaults.stringForKey("fileName")
            let scpPath = defaults.stringForKey("scpPath")
            let httpPath = defaults.stringForKey("httpPath")
            
            if fileName? && scpPath? && httpPath? {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.takeScreenshot(self)
                    }
                }
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
    
    func handledURL(aNotification: NSNotification?) -> Bool {
        
        if let urlString = aNotification?.userInfo["openUrl"] as? String {
            
            let url = NSURL.URLWithString(urlString)
            NSWorkspace.sharedWorkspace().openURL(url)
            println(url)
            
            NSApp.terminate(self)
            
            return true
        }
        
        return false
    }

    @IBAction func takeScreenshot(sender : NSObject) {
        
        window.miniaturize(self)
        NSRunningApplication.currentApplication().hide()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // do some async stuff
            
            let httpUrl = self.runSystemCallsAssync()
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                // do some main thread stuff stuff
                
                if httpUrl? {
                    let notification = NSUserNotification()
                    notification.title = "Screenshot uploaded to"
                    notification.informativeText = httpUrl
                    notification.userInfo = ["openUrl": httpUrl]
                    //notification.identifier = httpUrl
                    notification.soundName = "NSUserNotificationDefaultSoundName"
                    notification.actionButtonTitle = "Open"
                    notification.otherButtonTitle = ""
                    
                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(
                        notification
                    )
                    
                    NSApp.terminate(self)
                    
                } else {
                    self.window.orderFront(self)
                }
            }
        }
    }
    
    func runSystemCallsAssync() -> String! {
        
        let tmpName = NSTemporaryDirectory() + "nu.jabs.apps.ScreenshotUpload.png"
        
        systemCall("screencapture -i \(tmpName)")
        
        if NSFileManager.defaultManager().isReadableFileAtPath(tmpName) {
            
            let defaults = NSUserDefaults.standardUserDefaults()
            let fileName = defaults.stringForKey("fileName")
            let scpPath = defaults.stringForKey("scpPath")
            let httpPath = defaults.stringForKey("httpPath")
            
            systemCall("scp \(tmpName) \(scpPath)\(fileName)")
            systemCall("rm \(tmpName)")
            
            let httpUrl = "\(httpPath)\(fileName)"
            systemCall("echo \(httpUrl) | pbcopy")
            
            return httpUrl
        }
        
        return nil
    }
    
    func systemCall(cmd : String) {
        println(cmd)
        system(cmd.bridgeToObjectiveC().UTF8String)
    }

}

