//
//  MhubControlService.swift
//  MhubShortcuts
//
//  Created by Frank Lehmann on 10.01.22.
//

import Foundation
import AppKit

class MhubControlService {

    let baseUrl: URL
    
    init(baseUrl: URL = URL(string: "http://10.0.0.60")!) {
        self.baseUrl = baseUrl
    }
    
    var onStatusUpdate: ((Result<Mhub.StatusResponse, Mhub.Error>)->())? {
        didSet {
            // Initial fire
            onStatusUpdateObservingTimerFire()
        }
    }
    
    // MARK: - Continuous updates
    
    private var timer: Timer?
    private let interval: TimeInterval = 15
    
    func startStatusUpdateObserving() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(
            withTimeInterval: 15,
            repeats: true,
            block: { [weak self] _ in
                self?.onStatusUpdateObservingTimerFire()
            }
        )
    }
    
    func stopStatusUpdateObserving() {
        timer?.invalidate()
        timer = nil
    }
    
    private func onStatusUpdateObservingTimerFire() {
        getStatus { [weak self] result in
            self?.onStatusUpdate?(result)
        }
    }
    
    @objc func onWakeNote(note: NSNotification) {
        stopStatusUpdateObserving()
        startStatusUpdateObserving()
    }
    
    func setupWakeObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(onWakeNote(note:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
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
        print("MHUB Request: \(url.absoluteString)")
        urlSession.dataTask(
            with: url,
            completionHandler: { data, response, error in
                DispatchQueue.main.async {
                    print("MHUB Response: \(String(data: data ?? Data(), encoding: .utf8) ?? "")")
                    
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
        for routing: Mhub.Routing,
        completion: @escaping (Mhub.StatusResponse?, [Mhub.Error])->()
    ) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        var errors = [Mhub.Error]()
        
        let operations = routing.map { route in
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
                // Device returns old config directly after switching.
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    complete()
                }
            }
        }
    }
}

