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
    
    init(mhubControlService: MhubControlService) {
        self.mhubControlService = mhubControlService
        setup()
    }
    
    private var statusItem: NSStatusItem?
    
    @Persisted(as: "selectedRouting.json", in: .applicationSupportDirectory)
    private var selectedRouting: Mhub.Routing = CzvMhubConfiguration.hall.routing
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.imagePosition = .imageLeft
        statusItem?.button?.title = ""
        
        mhubControlService.onStatusUpdate = onStatusUpdate(result:)
    }
    
    func onStatusUpdate(result: Result<Mhub.StatusResponse, Mhub.Error>) {
        switch result {
        case .success(let response):
            let selectedCzvRouting = CzvMhubConfiguration(from: selectedRouting)
            if response.routing == selectedRouting {
                updateStatusItem(state: .selectedConfigActive, text: selectedCzvRouting?.title)
            } else {
                updateStatusItem(state: .selectedConfigInactive, text: selectedCzvRouting?.title)
            }
        case .failure(let error):
            switch error {
            case .networking:
                updateStatusItem(state: .error, text: "Offline")
            default:
                updateStatusItem(state: .error, text: "Fehler")
            }
        }
    }
    
    func updateStatusItem(state: MhubStatusItemState, text: String? = nil) {
        statusItem?.button?.image = state.image
        statusItem?.button?.title = text ?? ""
    }
}

enum MhubStatusItemState {
    case offline
    case error
    case selectedConfigActive
    case selectedConfigInactive
    
    var image: NSImage? {
        if #available(macOS 11.0, *) {
            switch self {
            case .offline, .error:
                return NSImage(systemSymbolName: "rectangle.slash", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 14, weight: .black, scale: .medium))
            case .selectedConfigActive:
                return NSImage(systemSymbolName: "checkmark.rectangle.fill", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 14, weight: .black, scale: .medium))
            case .selectedConfigInactive:
                return NSImage(systemSymbolName: "xmark.rectangle", accessibilityDescription: nil)?
                    .withSymbolConfiguration(.init(pointSize: 14, weight: .black, scale: .medium))
            }
        } else {
            return NSImage()
        }
    }
}
