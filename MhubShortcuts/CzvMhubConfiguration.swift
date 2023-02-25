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
    case appleTV
    
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
        case .appleTV:
            return [
                .a: .i8,
                .c: .i8,
                .d: .i8,
                .e: .i8,
                .f: .i8,
                .g: .i8
            ]
        }
    }
    
    var title: String {
        switch self {
        case .livestreamOffice:
            return "Büro"
        case .hall:
            return "Saal"
        case .appleTV:
            return "Apple TV"
        }
    }
    
    var menuItemTag: Int {
        switch self {
        case .livestreamOffice:
            return 100
        case .hall:
            return 200
        case .appleTV:
            return 999
        }
    }
    
    var keyEquivalent: String {
        switch self {
        case .livestreamOffice:
            return "1"
        case .hall:
            return "2"
        case .appleTV:
            return "3"
        }
    }
    
    static var configUrl: URL {
        URL(string: "https://10.0.0.60")!
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
            if element.routing == routing || routing.contains(element.routing) {
                self = element
                return
            }
        }
        return nil
    }
}
