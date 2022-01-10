//
//  MhubControlService.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 10.01.22.
//

import Foundation

class MhubControlService {

    let baseUrl: URL
    
    init(baseUrl: URL = URL(string: "http://10.0.0.60")!) {
        self.baseUrl = baseUrl
    }
    
    var onStatusUpdate: (()->())?
    
    // MARK: - Continuous updates
    
    let interval: TimeInterval = 15
    
    
    // MARK: - Networking general
    
    private lazy var urlSession = URLSession(configuration: .default)
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func request<ResponseData: Decodable>(
        url: URL,
        completion: @escaping (Result<ResponseData, Mhub.Error>)->()
    ) {
        urlSession.dataTask(
            with: url,
            completionHandler: { data, response, error in
                guard let data = data else {
                    completion(.failure(.networking(error)))
                    return
                }
                
                do {
                    let result = try self.decoder.decode(Mhub.Response<ResponseData>.self, from: data)
                    guard let data = result.data else {
                        completion(.failure(.noDataObject(result.error)))
                        return
                    }
                    completion(.success(data))
                } catch {
                    completion(.failure(.decoding(error)))
                }
            }
        ).resume()
    }
    
    // MARK: - API Requests
    
    func getStatus(completion: @escaping (Result<Mhub.StatusResponse, Mhub.Error>)->()) {
        let url = baseUrl.appendingPathComponent("/api/data/200/")
        request(url: url, completion: completion)
    }
    
    func performSwitch(
        output: Mhub.Output,
        input: Mhub.Input,
        completion: @escaping (Result<Mhub.SwitchResponse, Mhub.Error>)->()
    ) {
        let url = baseUrl.appendingPathComponent("/api/control/switch/\(output.rawValue)/\(input.rawValue)")
        request(url: url, completion: completion)
    }
    
    func performSwitch(
        for routes: Mhub.Routes,
        completion: @escaping (Mhub.StatusResponse?, [Mhub.Error])->()
    ) {
        let queue = OperationQueue()
        var errors = [Mhub.Error]()
        
        let operations = routes.map { route in
            AsyncBlockOperation { finish in
                self.performSwitch(output: route.key, input: route.value) { result in
                    if case .failure(let error) = result {
                        errors.append(error)
                    }
                    finish()
                }
            }
        }
        
        queue.addOperations(operations, waitUntilFinished: false)

        func complete() {
            self.getStatus { result in
                switch result {
                case .success(let result):
                    completion(result, errors)
                case .failure(let error):
                    errors.append(error)
                    completion(nil, errors)
                }
            }
        }
        
        if operations.isEmpty {
            complete()
        } else {
            queue.onCompletion {
                complete()
            }
        }
    }
}

