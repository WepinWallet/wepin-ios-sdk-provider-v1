import Foundation
import WepinCommon
import WepinModal
import WepinLogin
import WepinCore

public class WepinProvider: ProviderResolver {
    private var initialized: Bool = false
    private let wepinProviderManager: WepinProviderManager
    private let wepinProviderParams: WepinProviderParams
    private let platformType: String
    
    private var realProviders: [String: BaseProvider] = [:]
    private var middlewareProviders: [String: MiddlewareProvider] = [:]
    private var currentNetworkId: String?
    
    public var login: WepinLogin? {
        return wepinProviderManager.wepinLoginLib
    }
    
    //MARK: - Initialization
    public init(_ params: WepinProviderParams, platformType: String = "ios") {
        self.wepinProviderParams = params
        self.platformType = platformType
        self.wepinProviderManager = WepinProviderManager.shared
    }
    
    //MARK: - Public Methods
    public func initialize(attributes: WepinProviderAttributes) async throws -> Bool {
        if initialized {
            throw WepinError.alreadyInitialized
        }
        
        try await wepinProviderManager.initialize(params: wepinProviderParams, attributes: attributes, platformType: platformType)
        
        do {
            let providerNetworkInfo = try await WepinCore.shared.network.getNetworkInformation()
            ProviderNetworkInfo.shared.setNetworkInfo(providerNetworkInfo)
            initialized = true
        } catch {
            throw error
        }
        
        _ = await WepinCore.shared.session.checkLoginStatusAndGetLifeCycle()
        return initialized
    }
    
    public func finalize() {
        guard initialized else {
            return
        }
        
        wepinProviderManager.finalize()
        initialized = false
    }
    
    public func isInitialized() -> Bool {
        return initialized
    }
    
    public func changeLanguage(language: String) {
        wepinProviderManager.wepinAttributes?.defaultLanguage = language
    }
    
    public func getProvider(network: String, viewController: UIViewController? = nil) throws -> BaseProvider {
        print("getProvider for network: \(network)")
        
        if !initialized {
            print("not initialized")
            throw WepinError.notInitialized
        }
        
        // 이미 생성된 MiddlewareProvider가 있으면 동일한 객체 반환
        if let existingMiddleware = middlewareProviders[network] {
            print("Returning cached MiddlewareProvider for \(network)")
            return existingMiddleware
        }
        
        // 처음 요청시에만 실제 Provider와 MiddlewareProvider 생성
        try ensureRealProviderExists(network: network, viewController: viewController)
        
        // MiddlewareProvider 생성 시 self(ProviderResolver)로 전달
        let middlewareProvider = MiddlewareProvider(wepinProvider: self, targetNetwork: network)
        middlewareProviders[network] = middlewareProvider
        
        print("Created and cached MiddlewareProvider for \(network)")
        return middlewareProvider
    }
    
    private func ensureRealProviderExists(network: String, viewController: UIViewController?) throws {
        if realProviders[network] == nil || currentNetworkId != network {
            let realProvider = try createRealProviderForNetwork(network: network, viewController: viewController)
            setupNetworkChangeCallback(provider: realProvider, providerNetwork: network)
            
            realProviders[network] = realProvider
            currentNetworkId = network
            
            print("Created real provider: \(String(describing: type(of: realProvider))) for \(network)")
        }
    }
    
    private func createRealProviderForNetwork(network: String, viewController: UIViewController?) throws -> BaseProvider {
        print(" Creating real provider for network: \(network)")
        
        guard let networkInfo = ProviderNetworkInfo.shared.findNetworkInfoById(network) else {
            throw WepinError.notSupportedNetwork
        }
        
        let networkFamily = ProviderNetworkInfo.shared.getNetworkFamilyByNetwork(network)
        
        guard let rpc = networkInfo.rpcUrl.first else {
            throw WepinError.notSupportedNetwork
        }
        
        guard let vc = viewController ?? getTopViewController() else {
            throw WepinError.unknown("No view controller available")
        }
        
        switch networkFamily {
        case "evm":
            return EVMProvider(
                rpc: rpc,
                network: networkInfo.id,
                viewController: vc
            )
        case "kaia":
            return KaiaProvider(
                rpc: rpc,
                network: networkInfo.id,
                viewController: vc
            )
        default:
            throw WepinError.notSupportedNetwork
        }
    }
    
    /// 네트워크 변경 콜백 설정
    private func setupNetworkChangeCallback(provider: BaseProvider, providerNetwork: String) {
        
        let callback: (String, String) -> Void = { [weak self] currentNet, newNet in
            
            guard let self = self else { return }
            
            do {
                // 새로운 실제 Provider 생성
                let existingAddress = getSelectedAddress(network: newNet)?.address
                let newRealProvider = try self.createRealProviderForNetwork(network: newNet, viewController: nil)
                
                if let existingAddress = existingAddress {
                    let account = ProviderAccount(
                        address: existingAddress,
                        network: newNet
                    )
                    
                    if let evmProvider = newRealProvider as? EVMProvider {
                        evmProvider.setSelectedAccount(account)
                        evmProvider.setNetwork(newNet)
                    } else if let kaiaProvider = newRealProvider as? KaiaProvider {
                        kaiaProvider.setSelectedAccount(account)
                    }
                }
                
                self.setupNetworkChangeCallback(provider: newRealProvider, providerNetwork: newNet)
                
                // Dictionary 업데이트
                self.realProviders.removeAll()
                self.realProviders[newNet] = newRealProvider
                self.currentNetworkId = newNet
            } catch {
                print("Failed to update real provider: \(error.localizedDescription)")
            }
        }
        
        // Provider 타입에 따라 콜백 설정
        if let evmProvider = provider as? EVMProvider {
            evmProvider.setNetworkChangeCallback(callback)
        } else if let kaiaProvider = provider as? KaiaProvider {
            kaiaProvider.setNetworkChangeCallback(callback)
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        if Thread.isMainThread {
            return _getTopViewController()
        } else {
            var result: UIViewController?
            DispatchQueue.main.sync {
                result = _getTopViewController()
            }
            return result
        }
    }
    
    private func _getTopViewController() -> UIViewController? {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
    
    func getCurrentActiveRealProvider() -> BaseProvider? {
        guard let currentNetworkId = currentNetworkId else { return nil }
        return realProviders[currentNetworkId]
    }
    
    func getRealProviderForNetwork(_ network: String) -> BaseProvider? {
        do {
            try ensureRealProviderExists(network: network, viewController: nil)
            return realProviders[network]
        } catch {
            print("Failed to get real provider for network \(network): \(error)")
            return nil
        }
    }
    
    func getCurrentNetworkId() -> String? {
        return currentNetworkId
    }
}

