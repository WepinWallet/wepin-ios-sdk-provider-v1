import Foundation
import UIKit
import WepinCommon

/// 웹뷰 메서드 핸들러 클래스
class WebViewMethodHandler {
    private let viewController: UIViewController
    private let wepinProviderManager: WepinProviderManager
    
    private var networkChangeCallback: ((String, String) -> Void)?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        self.wepinProviderManager = WepinProviderManager.shared
    }
    
    func setNetworkChangeCallback(_ callback: @escaping (String, String) -> Void) {
        self.networkChangeCallback = callback
    }
    func enqueueAndOpen(_ request: WepinRequestMessage) async throws -> Any {
        guard let webViewManager = wepinProviderManager.wepinWebViewManager else {
            throw WepinError.notInitialized
        }
        webViewManager.openWidget(viewController: viewController)
        
        return try await webViewManager.enqueueRequest(request)
    }
    
    /// 계정 요청 메서드
    /// - Parameter network: 네트워크 ID
    /// - Returns: 요청 결과
    func requestAccounts(network: String) async throws -> Any {
        print("WebViewMethodHandler - requestAccounts")
        
        guard wepinProviderManager.wepinWebViewManager != nil else {
            throw WepinError.notInitialized
        }
        
        // 요청 메시지 생성
        let request = WepinRequestMessage(
            header: WepinRequestMessage.Header(id: Int(Date().timeIntervalSince1970 * 1000)),
            body: WepinRequestMessage.Body(
                command: "request_enable",
                parameter: RequestEnableParams(network: network)
            )
        )
        
        return try await enqueueAndOpen(request)
    }
    
    /// 트랜잭션 전송 메서드
    /// - Parameter transaction: 트랜잭션 파라미터
    /// - Returns: 요청 결과
    func sendTransaction(_ transaction: SignTransactionParams) async throws -> Any {
        print("WebViewMethodHandler - sendTransaction")
        
        guard let webViewManager = wepinProviderManager.wepinWebViewManager else {
            throw WepinError.notInitialized
        }
        
        let request = WepinRequestMessage(
            header: WepinRequestMessage.Header(id: Int(Date().timeIntervalSince1970 * 1000)),
            body: WepinRequestMessage.Body(
                command: "send_transaction",
                parameter: transaction
            )
        )
        
        return try await enqueueAndOpen(request)
    }
    
    /// 트랜잭션 서명 메서드
    /// - Parameter transaction: 트랜잭션 파라미터
    /// - Returns: 요청 결과
    func signTransaction(_ transaction: SignTransactionParams) async throws -> Any {
        print("WebViewMethodHandler - signTransaction")
        
        guard let webViewManager = wepinProviderManager.wepinWebViewManager else {
            throw WepinError.notInitialized
        }
        
        let request = WepinRequestMessage(
            header: WepinRequestMessage.Header(id: Int(Date().timeIntervalSince1970 * 1000)),
            body: WepinRequestMessage.Body(
                command: "sign_transaction",
                parameter: transaction
            )
        )
        
        return try await enqueueAndOpen(request)
    }
    
    /// 메시지 서명 메서드
    /// - Parameter parameter: 서명 파라미터
    /// - Returns: 요청 결과
    func sign(_ parameter: SignParams) async throws -> Any {
        print("WebViewMethodHandler - sign")
        
        guard let webViewManager = wepinProviderManager.wepinWebViewManager else {
            throw WepinError.notInitialized
        }
        
        let request = WepinRequestMessage(
            header: WepinRequestMessage.Header(id: Int(Date().timeIntervalSince1970 * 1000)),
            body: WepinRequestMessage.Body(
                command: "sign",
                parameter: parameter
            )
        )
        
        return try await enqueueAndOpen(request)
    }
    
    /// 타입 데이터 서명 메서드
    /// - Parameter parameter: 타입 데이터 서명 파라미터
    /// - Returns: 요청 결과
    func signTypedData(_ parameter: SignTypedDataParams) async throws -> Any {
        print("WebViewMethodHandler - signTypedData")
        
        guard let webViewManager = wepinProviderManager.wepinWebViewManager else {
            throw WepinError.notInitialized
        }
        
        let request = WepinRequestMessage(
            header: WepinRequestMessage.Header(id: Int(Date().timeIntervalSince1970 * 1000)),
            body: WepinRequestMessage.Body(
                command: "sign_typed_data",
                parameter: parameter
            )
        )
        
        return try await enqueueAndOpen(request)
    }
    
    /// 체인 전환 메서드
    /// - Parameters:
    ///   - network: 네트워크 ID
    ///   - chainId: 체인 ID
    /// - Returns: 요청 결과
    func switchChain(network: String, chainId: String) async throws -> Any {
        print("WebViewMethodHandler - switchChain")
        
        guard let webViewManager = wepinProviderManager.wepinWebViewManager else {
            throw WepinError.notInitialized
        }
        
        let request = WepinRequestMessage(
            header: WepinRequestMessage.Header(id: Int(Date().timeIntervalSince1970 * 1000)),
            body: WepinRequestMessage.Body(
                command: "wallet_switchEthereumChain",
                parameter: SwitchEthChainParams(
                    account: ProviderAccount(address: "", network: network),
                    chainId: chainId
                )
            )
        )
        
        // 웹뷰 요청 처리
        do {
            let result = try await enqueueAndOpen(request)
            print("switchChain completed successfully result: \(result)")
            
            // 체인 변경 성공 시 네트워크 변경 처리
            handleNetworkChangeResult(currentNetwork: network, result: result)
            
            return result
        } catch {
            print("switchChain failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func handleNetworkChangeResult(currentNetwork: String, result: Any) {
        do {
            let accountInfo: ProviderAccount?
            
            if let resultString = result as? String,
               let data = resultString.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                accountInfo = ProviderAccount(
                    address: json["address"] as? String ?? "",
                    network: json["network"] as? String ?? ""
                )
            } else if let resultDict = result as? [String: Any] {
                accountInfo = ProviderAccount(
                    address: resultDict["address"] as? String ?? "",
                    network: resultDict["network"] as? String ?? ""
                )
            } else {
                print("unknown result type")
                accountInfo = nil
            }
            
            if let accountInfo = accountInfo,
               !accountInfo.address.isEmpty,
               !accountInfo.network.isEmpty {
                
                setSelectedAddress(network: accountInfo.network, address: accountInfo.address)
                handleNetworkChange(currentNetwork: currentNetwork, newNetwork: accountInfo.network)
            }
            
        } catch {
            print("Error handling network change: \(error.localizedDescription)")
        }
    }
    
    private func handleNetworkChange(currentNetwork: String, newNetwork: String) {
        print("handleNetworkChange - currentNetwork: \(currentNetwork), network: \(newNetwork)")
        
        // 네트워크가 실제로 변경되었는지 확인
        if currentNetwork == newNetwork {
            print("Network not changed, staying on: \(currentNetwork)")
            return
        }
        
        // 네트워크 패밀리 변경 여부 확인
        let currentFamily = ProviderNetworkInfo.shared.getNetworkFamilyByNetwork(currentNetwork)
        let newFamily = ProviderNetworkInfo.shared.getNetworkFamilyByNetwork(newNetwork)
        
        print("Network family change: \(currentFamily) -> \(newFamily)")
        
        // 네트워크 패밀리가 변경되면 콜백 호출
        if currentFamily != newFamily {
            print("Network family changed - switching provider")
            networkChangeCallback?(currentNetwork, newNetwork)
        } else {
            print("Same network family - but different network, still switching")
            // 같은 패밀리라도 네트워크가 다르면 콜백 호출 (예: ethereum -> polygon)
            networkChangeCallback?(currentNetwork, newNetwork)
        }
    }
}
