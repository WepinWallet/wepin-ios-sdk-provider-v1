import Foundation

// MARK: - BaseProvider Protocol
public protocol BaseProvider {
    // Common methods for all networks
    func request(method: String, params: [Any]?) async throws -> Any
    func switchChain(chainId: String) async throws -> Any
    func switchNetwork(network: String) async throws -> Any
    
    // Generic RPC methods
    func send(method: String, params: [Any]) async throws -> Any
    
    func getNetwork() -> String
    func getNetworkFamily() -> String
}

// MARK: - EVMProviderInterface Protocol
protocol EVMProviderInterface: BaseProvider {
    func requestAccounts() async throws -> Any
    
    func sendTransaction(transaction: [String: Any]) async throws -> Any
    func signTransaction(transaction: [String: Any]) async throws -> Any
    func sign(data: String, address: String) async throws -> Any
    func signTypedDataV1(data: [[String: Any]], address: String) async throws -> Any
    func signTypedDataV3(data: [String: Any], address: String) async throws -> Any
    func signTypedDataV4(data: [String: Any], address: String) async throws -> Any
}

// MARK: - KaiaProviderInterface Protocol
protocol KaiaProviderInterface: EVMProviderInterface {
    // 현재 KaiaProviderInterface는 EVMProviderInterface와 동일하지만,
    // 필요에 따라 추가 메서드가 구현될 수 있습니다.
}
