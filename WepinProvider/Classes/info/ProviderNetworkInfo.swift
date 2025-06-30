import Foundation
import WepinCore

// MARK: - ProviderNetworkInfo
public class ProviderNetworkInfo {
    public static let shared = ProviderNetworkInfo()
    
    private var _networkInfo: NetworkInfoResponse?
    
    private init() {}
    
    // 네트워크 정보 설정
    internal func setNetworkInfo(_ networkInfo: NetworkInfoResponse) {
        _networkInfo = networkInfo
    }
    
    // 네트워크 정보 반환
    internal func getNetworkInfo() -> NetworkInfoResponse? {
        return _networkInfo
    }
    
    // ID로 네트워크 정보 찾기
    internal func findNetworkInfoById(_ id: String) -> NetworkInfo? {
        return _networkInfo?.networks.first { $0.id == id }
    }
    
    // 네트워크 이름으로 네트워크 패밀리 찾기
    public func getNetworkFamilyByNetwork(_ network: String) -> String? {
        let lowercasedNetwork = network.lowercased()
        
        if lowercasedNetwork == "ethereum" || lowercasedNetwork.hasPrefix("evm") {
            return "evm"
        } else if lowercasedNetwork.hasPrefix("klaytn") || lowercasedNetwork.hasPrefix("kaia") {
            return "kaia"
        } else {
            return nil
        }
    }
}
