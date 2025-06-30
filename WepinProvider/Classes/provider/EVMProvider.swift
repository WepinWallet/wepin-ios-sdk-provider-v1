import Foundation
import UIKit
import WepinCommon
import WepinCore

/// EVM 프로바이더 클래스
class EVMProvider: EVMProviderInterface {
    private let rpc: JsonRpcUrl
    private let network: String
    private let viewController: UIViewController
    
    private let webViewMethodHandler: WebViewMethodHandler
    private let rpcMethodHandler: RpcMethodHandler
    
    private var selectedAccount: ProviderAccount?
    private var currentNetwork: String
    
    private var networkChangeCallback: ((String, String) -> Void)?
    
    init(rpc: JsonRpcUrl, network: String, viewController: UIViewController) {
        self.rpc = rpc
        self.network = network
        self.viewController = viewController
        self.currentNetwork = network
        
        self.webViewMethodHandler = WebViewMethodHandler(viewController: viewController)
        self.rpcMethodHandler = RpcMethodHandler(rpc: rpc)
    }
    
    func setNetworkChangeCallback(_ callback: @escaping (String, String) -> Void) {
        self.networkChangeCallback = callback
        
        // WebViewMethodHandler에도 콜백 설정
        webViewMethodHandler.setNetworkChangeCallback { [weak self] currentNet, newNet in
            print("EVM WebView network change: \(currentNet) -> \(newNet)")
            self?.networkChangeCallback?(currentNet, newNet)
        }
    }
    
    func setSelectedAccount(_ account: ProviderAccount) {
        selectedAccount = account
    }
    
    func setNetwork(_ network: String) {
        currentNetwork = network
    }
    
    /// 네트워크 ID 반환
    func getNetwork() -> String {
        return currentNetwork
    }
    
    /// 네트워크 패밀리 반환
    func getNetworkFamily() -> String {
        return "evm"
    }
    
    /// 계정 요청
    func requestAccounts() async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            print("invalid login session")
            throw WepinError.invalidLoginSessionSimple
        }
        do {
            if let address = getSelectedAddress(network: network) {
                currentNetwork = address.network
                setSelectedAccount(ProviderAccount(address: address.address, network: address.network))
                return [address.address]
            }
            let result = try await webViewMethodHandler.requestAccounts(network: network)
            
            // 결과 파싱
            if let jsonData = try? JSONSerialization.data(withJSONObject: result),
               let jsonString = String(data: jsonData, encoding: .utf8),
               let data = jsonString.data(using: .utf8),
               let addresses = try? JSONSerialization.jsonObject(with: data) as? [String] {
                
                if let firstAddress = addresses.first?.lowercased(), !firstAddress.isEmpty {
                    selectedAccount = ProviderAccount(
                        address: firstAddress,
                        network: currentNetwork
                    )
                    setSelectedAddress(network: currentNetwork, address: firstAddress)
                    
                    return [firstAddress]
                }
                
                return addresses
            } else {
                throw EVMError.internalError
            }
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
    }
    
    /// 체인 전환
    func switchChain(chainId: String) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        return try await webViewMethodHandler.switchChain(network: network, chainId: chainId)
    }
    
    /// 네트워크 전환
    func switchNetwork(network: String) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        guard let chainId = ProviderNetworkInfo.shared.findNetworkInfoById(network)?.chainId else {
            throw EVMError.invalidParams
        }
        
        return try await webViewMethodHandler.switchChain(network: network, chainId: chainId)
    }
    
    /// 트랜잭션 전송
    func sendTransaction(transaction: [String: Any]) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        guard let account = selectedAccount else {
            throw EVMError.unauthorized
        }
        
        // 현재 네트워크와 계정의 네트워크가 다른 경우
        if account.network != currentNetwork {
            throw EVMError.chainDisconnected
        }
        
        // 파라미터 유효성 검사
        if !isValidEvmParams(params: transaction) {
            throw EVMError.invalidParams
        }
        
        // 트랜잭션 파라미터 변환
        let params: SignTransactionParams
        do {
            let standardParams = parseStandardTransactionParams(transaction)
            params = try standardParams.toSignTransactionParams(account: account)
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.invalidParams
        }
        
        // 트랜잭션 전송 요청
        return try await webViewMethodHandler.sendTransaction(params)
    }
    
    /// 트랜잭션 서명
    func signTransaction(transaction: [String: Any]) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        guard let account = selectedAccount else {
            throw EVMError.unauthorized
        }
        
        // 현재 네트워크와 계정의 네트워크가 다른 경우
        if account.network != currentNetwork {
            throw EVMError.chainDisconnected
        }
        
        // 파라미터 유효성 검사
        if !isValidEvmParams(params: transaction) {
            throw EVMError.invalidParams
        }
        
        // 트랜잭션 파라미터 변환
        let params: SignTransactionParams
        do {
            let standardParams = parseStandardTransactionParams(transaction)
            params = try standardParams.toSignTransactionParams(account: account)
            return try await webViewMethodHandler.signTransaction(params)
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
        
    }
    
    /// 메시지 서명
    func sign(data: String, address: String) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        guard let account = selectedAccount else {
            throw EVMError.unauthorized
        }
        
        if account.address.lowercased() != address.lowercased() {
            print("address not equal account: \(account)")
            throw EVMError.invalidParams
        }
        
        // 현재 네트워크와 계정의 네트워크가 다른 경우
        if account.network != currentNetwork {
            throw EVMError.chainDisconnected
        }
        
        // 서명 파라미터 생성
        let params = SignParams(
            account: account,
            data: data
        )
        
        // 메시지 서명 요청
        do {
            return try await webViewMethodHandler.sign(params)
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
    }
    
    /// 타입 데이터 V1 서명
    func signTypedDataV1(data: [[String: Any]], address: String) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        // JSON 직렬화
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        do {
            return try await signTypedData(data: jsonString, address: address, version: "V1")
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
    }
    
    /// 타입 데이터 V3 서명
    func signTypedDataV3(data: [String: Any], address: String) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        // JSON 직렬화
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        do {
            return try await signTypedData(data: jsonString, address: address, version: "V3")
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
    }
    
    /// 타입 데이터 V4 서명
    func signTypedDataV4(data: [String: Any], address: String) async throws -> Any {
        guard WepinCore.shared.storage.getStorage(key: "user_info", type: StorageDataType.UserInfo.self) != nil else {
            throw WepinError.invalidLoginSessionSimple
        }
        
        // JSON 직렬화
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        do {
            return try await signTypedData(data: jsonString, address: address, version: "V4")
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
    }
    
    /// 타입 데이터 서명 내부 구현
    private func signTypedData(data: String, address: String, version: String) async throws -> Any {
        guard let account = selectedAccount else {
            throw EVMError.unauthorized
        }
        
        if account.address.lowercased() != address.lowercased() {
            throw EVMError.unauthorized
        }
        
        // 현재 네트워크와 계정의 네트워크가 다른 경우
        if account.network != currentNetwork {
            throw EVMError.chainDisconnected
        }
        
        // 타입 데이터 서명 파라미터 생성
        let params = SignTypedDataParams(
            account: account,
            data: data,
            version: version
        )
        
        // 타입 데이터 서명 요청
        do {
            return try await webViewMethodHandler.signTypedData(params)
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
    }
    
    /// RPC 요청 전송
    func send(method: String, params: [Any]) async throws -> Any {
        do {
            return try await rpcMethodHandler.send(method: method, params: params)
        } catch {
            if let evmError = error as? EVMError {
                throw evmError
            }
            throw EVMError.internalError
        }
    }
    
    /// 일반 요청 처리
    func request(method: String, params: [Any]?) async throws -> Any {
        switch method {
        case "eth_requestAccounts", "eth_accounts":
            return try await requestAccounts()
            
        case "eth_sendTransaction":
            guard let params = params, let firstParam = params.first as? [String: Any] else {
                throw EVMError.invalidParams
            }
            return try await sendTransaction(transaction: firstParam)
            
        case "eth_signTransaction":
            guard let params = params, let firstParam = params.first as? [String: Any] else {
                throw EVMError.invalidParams
            }
            return try await signTransaction(transaction: firstParam)
            
        case "eth_signTypedData_v1":
            guard let params = params, params.count >= 2,
                  let address = params[0] as? String,
                  let typedDataList = params[1] as? [[String: Any]] else {
                throw EVMError.invalidParams
            }
            return try await signTypedDataV1(data: typedDataList, address: address)
            
        case "eth_signTypedData_v3", "eth_signTypedData_v4":
            guard let params = params, params.count >= 2,
                  let address = params[0] as? String,
                  let data = params[1] as? [String: Any] else {
                throw EVMError.invalidParams
            }
            
            if method == "eth_signTypedData_v3" {
                return try await signTypedDataV3(data: data, address: address)
            } else {
                return try await signTypedDataV4(data: data, address: address)
            }
            
        case "eth_sign":
            guard let params = params, params.count >= 2,
                  let address = params[0] as? String,
                  let data = params[1] as? String else {
                throw EVMError.invalidParams
            }
            return try await sign(data: data, address: address)
            
        case "personal_sign":
            guard let params = params, params.count >= 2,
                  let data = params[0] as? String,
                  let address = params[1] as? String else {
                throw EVMError.invalidParams
            }
            return try await sign(data: data, address: address)
            
        case "wallet_switchEthereumChain":
            guard let params = params, let firstParam = params.first as? [String: Any],
                  let chainId = firstParam["chainId"] as? String else {
                throw EVMError.invalidParams
            }
            return try await switchChain(chainId: chainId)
            
        default:
            return try await rpcMethodHandler.send(method: method, params: params)
        }
    }
    
    /// 16진수 문자열 확인
    private func isHexString(_ value: String?) -> Bool {
        guard let value = value else { return false }
        return value.hasPrefix("0x") &&
        value.count > 2 &&
        value.dropFirst(2).allSatisfy { $0.isHexDigit }
    }
    
    /// EVM 파라미터 유효성 검사
    private func isValidEvmParams(params: [String: Any]) -> Bool {
        for (key, value) in params {
            if let stringValue = value as? String, !isHexString(stringValue) {
                print("ParamChecker: \(key) = \(stringValue) is not a valid hex string")
                return false
            }
        }
        return true
    }
}
