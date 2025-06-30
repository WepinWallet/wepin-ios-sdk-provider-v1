//
//  MiddlewareProvider.swift
//  Pods
//
//  Created by iotrust on 6/25/25.
//
import Foundation
import UIKit
import WepinCommon

internal class MiddlewareProvider: BaseProvider {
    private weak var wepinProvider: ProviderResolver?
    private let targetNetwork: String
    
    private let TAG = "MiddlewareProvider"
    
    init(wepinProvider: ProviderResolver, targetNetwork: String) {
        self.wepinProvider = wepinProvider
        self.targetNetwork = targetNetwork
    }
    
    /// 현재 활성화된 실제 Provider 가져오기
    private func getCurrentRealProvider() -> BaseProvider? {
        return wepinProvider?.getCurrentActiveRealProvider() ??
               wepinProvider?.getRealProviderForNetwork(targetNetwork)
    }
    
    // MARK: - BaseProvider 인터페이스 구현 - 모든 요청을 실제 Provider로 위임
    
    public func request(method: String, params: [Any]?) async throws -> Any {
        print("\(TAG) routing request: \(method) to \(getCurrentRealProvider()?.getNetworkFamily() ?? "unknown")")
        
        guard let provider = getCurrentRealProvider() else {
            throw WepinError.unknown("No active provider for \(method)")
        }
        
        return try await provider.request(method: method, params: params)
    }
    
    public func switchChain(chainId: String) async throws -> Any {
        guard let provider = getCurrentRealProvider() else {
            throw WepinError.unknown("No active provider")
        }
        
        return try await provider.switchChain(chainId: chainId)
    }
    
    public func switchNetwork(network: String) async throws -> Any {
        guard let provider = getCurrentRealProvider() else {
            throw WepinError.unknown("No active provider")
        }
        
        return try await provider.switchNetwork(network: network)
    }
    
    public func send(method: String, params: [Any]) async throws -> Any {
        guard let provider = getCurrentRealProvider() else {
            throw WepinError.unknown("No active provider")
        }
        
        return try await provider.send(method: method, params: params)
    }
    
    public func getNetwork() -> String {
        return getCurrentRealProvider()?.getNetwork() ?? targetNetwork
    }
    
    public func getNetworkFamily() -> String {
        return getCurrentRealProvider()?.getNetworkFamily() ?? "unknown"
    }
    
    // MARK: - 디버깅용 메서드들
    
    func getCurrentProviderType() -> String {
        return String(describing: type(of: getCurrentRealProvider()))
    }
    
    func getCurrentProviderInfo() -> String {
        guard let provider = getCurrentRealProvider() else {
            return "Middleware -> None"
        }
        return "Middleware -> \(String(describing: type(of: provider))) (\(provider.getNetwork()), \(provider.getNetworkFamily()))"
    }
}
