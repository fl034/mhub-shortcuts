//
//  PersistedProperty.swift
//
//
//  Created by Frank Lehmann on 30.10.19.
//
//

import Foundation

fileprivate var backgroundQueue = DispatchQueue(label: "PersistedProperty", qos: .background)



protocol PersistedPropertyProtocol {
    associatedtype Value: Codable
    
    var encoder: JSONEncoder? { get }
    var decoder: JSONDecoder? { get }
    
    var path: String { get }
    var directory: FileManager.SearchPathDirectory { get }
}

extension PersistedPropertyProtocol {
    var localUrl: URL? {
        if let url = FileManager.default.urls(for: directory, in: .userDomainMask).first {
            return url.appendingPathComponent(path, isDirectory: false)
        }
        print("PersistedProperty: Couldn't create local url.")
        return nil
    }
    
    func saveToOrRemoveFromDiskAsync(_ value: Value?, using encoder: JSONEncoder?) {
        backgroundQueue.async {
            let encoder = encoder ?? JSONEncoder()
            
            do {
                guard let url = self.localUrl, !url.hasDirectoryPath else {
                    throw NSError(domain: "PersistedProperty: Couldn't create local url or path ends with slash", code: 0, userInfo: nil)                    
                }
                
                if value == nil {
                    try FileManager.default.removeItem(at: url)
                } else {
                    let data = try encoder.encode(value!)
                    try FileManager.default.createSubfoldersForFileUrlIfNeeded(at: url)
                    try data.write(to: url, options: .atomic)
                }
            } catch {
                print(error)
            }
        }
    }
    
    func retrieveFromDisk(using decoder: JSONDecoder?) -> Value? {
        guard let url = localUrl, !url.hasDirectoryPath else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        let decoder = decoder ?? JSONDecoder()
        
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(Value.self, from: data)
        } catch {
            print(error)
        }
        
        return nil
    }
}

@propertyWrapper
struct PersistedOptional<Value: Codable>: PersistedPropertyProtocol {
    let encoder: JSONEncoder?
    let decoder: JSONDecoder?

    var path: String
    var directory: FileManager.SearchPathDirectory
    
    init(as path: String, in directory: FileManager.SearchPathDirectory, custom encoder: JSONEncoder? = nil, _ decoder: JSONDecoder? = nil) {
        self.path = path
        self.directory = directory
        self.encoder = encoder
        self.decoder = decoder
        self._value = retrieveFromDisk(using: decoder)
    }
    
    private var _value: Value?
    
    var wrappedValue: Value? {
        mutating get {
            _value
        }
        set {
            _value = newValue
            saveToOrRemoveFromDiskAsync(newValue, using: encoder)
        }
    }
    
    mutating func reloadFromDisk() {
        _value = retrieveFromDisk(using: decoder
)
    }
}

@propertyWrapper
struct Persisted<Value: Codable>: PersistedPropertyProtocol {
    let encoder: JSONEncoder?
    let decoder: JSONDecoder?
    
    let path: String
    let directory: FileManager.SearchPathDirectory
        
    init(wrappedValue value: Value, as path: String, in directory: FileManager.SearchPathDirectory, custom encoder: JSONEncoder? = nil, _ decoder: JSONDecoder? = nil) {
        self.path = path
        self.directory = directory
        self.encoder = encoder
        self.decoder = decoder
        _value = value
        if let persistedValue = retrieveFromDisk(using: decoder) {
            _value = persistedValue
        } else {
            wrappedValue = value
        }
    }
    
    private var _value: Value
    var wrappedValue: Value {
        get {
            _value
        }
        set {
            _value = newValue
            saveToOrRemoveFromDiskAsync(newValue, using: encoder)
        }
    }
}


extension FileManager {
    /// Create necessary sub folders before creating a file
    func createSubfoldersForFileUrlIfNeeded(at url: URL) throws {
        do {
            guard !url.hasDirectoryPath else { return }
            
            let subfolderUrl = url.deletingLastPathComponent()
            var subfolderExists = false
            var isDirectory: ObjCBool = false
            if self.fileExists(atPath: subfolderUrl.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    subfolderExists = true
                }
            }
            if !subfolderExists {
                try FileManager.default.createDirectory(at: subfolderUrl, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            throw error
        }
    }
    
}
