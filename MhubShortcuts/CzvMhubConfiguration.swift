//
//  CzvMhubConfiguration.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 11.01.22.
//

import Foundation

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
                .f: .i3,
                .g: .i3
            ]
        case .hall:
            return [
                .a: .i2,
                .c: .i1,
                .d: .i1,
                .e: .i1,
                .f: .i1,
                .g: .i1
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
    
    var menuItemTag: Int {
        switch self {
        case .livestreamOffice:
            return 100
        case .hall:
            return 200
        }
    }
    
    init?(from tag: Int) {
        for element in Self.allCases {
            if element.menuItemTag == tag {
                self = element
                return
            }
        }
        return nil
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
