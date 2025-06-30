//
//  ProviderResolver.swift
//  Pods
//
//  Created by iotrust on 6/25/25.
//


import Foundation

/// Provider 해결 인터페이스
protocol ProviderResolver: AnyObject {
    func getCurrentActiveRealProvider() -> BaseProvider?
    func getRealProviderForNetwork(_ network: String) -> BaseProvider?
    func getCurrentNetworkId() -> String?
}
