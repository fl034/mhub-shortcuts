//
//  StatusItemProvider.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 10.01.22.
//

import Foundation
import AppKit

enum CzvMhubConfiguration: CaseIterable {
    case livestreamOffice
    case hall
    
    var routing: Mhub.Routing {
        switch self {
        case .livestreamOffice:
            return [
                .a: .i4,
                .c: .i3,
                .d: .i3,
                .e: .i3,
                .f: .i3
            ]
        case .hall:
            return [
                .a: .i2,
                .c: .i1,
                .d: .i1,
                .e: .i1,
                .f: .i1
            ]
        }
    }
    
    var title: String {
        switch self {
        case .livestreamOffice:
            return "Büro"
        case .hall:
            return "Saal"
        }
    }
    
    init?(from routing: Mhub.Routing) {
        for element in Self.allCases {
            if element.routing == routing {
                self = element
                return
            }
        }
        return nil
    }
}

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
