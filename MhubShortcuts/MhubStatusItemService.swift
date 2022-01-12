//
//  StatusItemProvider.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 10.01.22.
//

import Foundation
import AppKit


class MhubStatusItemService {
    
    private let mhubControlService: MhubControlService
    
    init(mhubControlService: MhubControlService = MhubControlService()) {
        self.mhubControlService = mhubControlService
        setup()
    }
    
    private var statusItem: NSStatusItem?
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.imagePosition = .imageLeft
        statusItem?.button?.title = ""
        
        mhubControlService.startStatusUpdateObserving()
        updateStatusItem(state: .offline, text: "", statusResponse: nil)
        mhubControlService.onStatusUpdate = onStatusUpdate(result:)
    }
    
    func onStatusUpdate(result: Result<Mhub.StatusResponse, Mhub.Error>) {
        switch result {
        case .success(let response):
            if let selectedCzvRouting = CzvMhubConfiguration(from: response.routing) {
                updateStatusItem(state: .knownRouting, text: selectedCzvRouting.title, statusResponse: response)
            } else {
                updateStatusItem(state: .unknownRouting, text: nil, statusResponse: response)
            }
        case .failure(let error):
            switch error {
            case .networking:
                updateStatusItem(state: .error, text: "Offline", statusResponse: nil)
            default:
                updateStatusItem(state: .error, text: "Fehler", statusResponse: nil)
            }
        }
    }
    
    func updateStatusItem(state: MhubStatusItemState, text: String? = nil, statusResponse: Mhub.StatusResponse?) {
        statusItem?.button?.image = state.image
        statusItem?.button?.title = text ?? ""
        setupMenu(with: statusResponse)
    }
    
    // MARK: - Menu
    
    func setupMenu(with statusResponse: Mhub.StatusResponse? = nil) {
        let menu = NSMenu()
                       
        menu.addItem(NSMenuItem(title: "HDMI Matrix", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        for config in CzvMhubConfiguration.allCases {
            let item = NSMenuItem(title: config.title, action: #selector(didSelectConfigFromMenu), keyEquivalent: "")
            item.isEnabled = true
            item.target = self
            
            if statusResponse?.routing.contains(config.routing) ?? false {
                item.state = .on
            } else {
                item.state = .off
            }
            
            item.tag = config.menuItemTag
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func didSelectConfigFromMenu(_ sender: NSMenuItem) {
        guard let config = CzvMhubConfiguration.init(from: sender.tag) else {
            updateStatusItem(state: .error, text: "Wrong tag", statusResponse: nil)
            setupMenu()
            return
        }
        
        updateStatusItem(state: .loading, text: config.title, statusResponse: nil)
        
        mhubControlService.performSwitch(for: config.routing) { [weak self] statusResponse, errors in
            if let statusResponse = statusResponse {
                self?.onStatusUpdate(result: .success(statusResponse))
            } else {
                self?.onStatusUpdate(result: .failure(errors.last ?? .noDataObject(nil)))
            }
        }
    }

}

enum MhubStatusItemState {
    case offline
    case error
    case loading
    case knownRouting
    case unknownRouting
    
    var image: NSImage? {
        switch self {
        case .loading:
            return #imageLiteral(resourceName: "rectangle.dashed")
        case .offline, .error:
            return #imageLiteral(resourceName: "rectangle.slash")
        case .knownRouting:
            return #imageLiteral(resourceName: "checkmark.rectangle.fill")
        case .unknownRouting:
            return #imageLiteral(resourceName: "xmark.rectangle")
        }
    }
}
