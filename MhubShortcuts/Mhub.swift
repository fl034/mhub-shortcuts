//
//  Mhub.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 10.01.22.
//

import Foundation

struct Mhub {
    enum State {
        case offline
        case online(Routes)
    }
    
    enum Input: String, Codable, Hashable {
        case i1 = "1"
        case i2 = "2"
        case i3 = "3"
        case i4 = "4"
        case i5 = "5"
        case i6 = "6"
        case i7 = "7"
        case i8 = "8"
    }
    
    enum Output: String, Codable, Hashable {
        case a,b,c,d,e,f,g,h
    }
    
    struct Zone: Codable {
        let zoneId: String?
        let state: [State]?
        
        struct State: Codable {
            let outputId: Mhub.Output?
            let inputId: Mhub.Input?
            let displayPower: String?
        }
    }
    
    typealias Routes = [Output: Input]
    
    // MARK: - API
    
    enum Error: Swift.Error {
        case inResponse(ResponseError)
        case networking(Swift.Error?)
        case decoding(Swift.Error?)
        case noDataObject(ResponseError?)
    }
    
    struct StatusResponse: Decodable {
        let zones: [Zone]?
    }
    
    struct SwitchResponse: Decodable {
        let inputId: Input
        let outputId: Output
    }
    
    struct Response<DataObject: Decodable>: Decodable {
        let data: DataObject?
        let header: ResponseHeader?
        let error: ResponseError?
    }
    
    struct ResponseHeader: Codable {
        let version: String?
    }
    
    struct ResponseError: Codable {
        let code: String?
    }
}
