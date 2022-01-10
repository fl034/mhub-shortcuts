//
//  StatusItemProvider.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 10.01.22.
//

import Foundation
import AppKit

class MhubStatusItemService {
    
    private var statusItem: NSStatusItem?
    
    init() {
        setup()
    }
    
    func setup() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }
}
