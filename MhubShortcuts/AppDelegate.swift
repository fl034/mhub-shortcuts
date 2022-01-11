//
//  AppDelegate.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 10.01.22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    lazy var statusItemService = MhubStatusItemService()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = statusItemService 
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

