//
//  WepinPinTypes.swift
//  Pods
//
//  Created by iotrust on 3/20/25.
//
import WepinCommon
@_exported import WepinLogin

public struct WepinProviderParams {
    
    public var appId: String
    public var appKey: String
    
    public init(appId: String, appKey: String) {
        self.appId = appId
        self.appKey = appKey
    }
}

extension WepinAttribute {
    public init(language: String) {
        self.init(defaultLanguage: language)
    }
}

public typealias WepinProviderAttributes = WepinAttribute

// MARK: - ProviderAccount
struct ProviderAccount {
    let address: String
    let network: String
    
    func toDictionary() -> [String: Any] {
        return [
            "address": address,
            "network": network
        ]
    }
}

// MARK: - WepinRequestMessage
public struct WepinRequestMessage {
    public struct Header {
        public let id: Int
        
        public init(id: Int) {
            self.id = id
        }
    }
    
    public struct Body {
        public let command: String
        public let parameter: Any
        
        public init(command: String, parameter: Any) {
            self.command = command
            self.parameter = parameter
        }
    }
    
    public let header: Header
    public let body: Body
    
    public init(header: Header, body: Body) {
        self.header = header
        self.body = body
    }
    
    public func toMap() -> [String: Any] {
        return [
            "header": [
                "request_from": "native",
                "request_to": "wepin_widget",
                "id": header.id
            ],
            "body": [
                "command": body.command,
                "parameter": body.parameter
            ]
        ]
    }
}

// MARK: - RequestEnableParams
struct RequestEnableParams {
    let network: String
    
    func toDictionary() -> [String: Any] {
        return ["network": network]
    }
}

// MARK: - SignParams
struct SignParams {
    let account: ProviderAccount
    let data: String
    
    func toDictionary() -> [String: Any] {
        return [
            "account": account.toDictionary(),
            "data": data
        ]
    }
}

// MARK: - SignTransactionParams
struct SignTransactionParams {
    let account: ProviderAccount
    let to: String
    let from: String
    let value: String?
    let gas: String?
    let gasPrice: String?
    let data: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "account": account.toDictionary(),
            "to": to,
            "from": from
        ]
        
        if let value = value { dict["value"] = value }
        if let gas = gas { dict["gas"] = gas }
        if let gasPrice = gasPrice { dict["gasPrice"] = gasPrice }
        if let data = data { dict["data"] = data }
        
        return dict
    }
}

// MARK: - SignTypedDataParams
struct SignTypedDataParams {
    let account: ProviderAccount
    let data: String
    let version: String
    
    func toDictionary() -> [String: Any] {
        return [
            "account": account.toDictionary(),
            "data": data,
            "version": version
        ]
    }
}

// MARK: - SwitchEthChainParams
struct SwitchEthChainParams {
    let account: ProviderAccount
    let chainId: String
    
    func toDictionary() -> [String: Any] {
        return [
            "account": account.toDictionary(),
            "chainId": chainId
        ]
    }
}

// MARK: - Extension to convert transaction params
extension [String: Any] {
    func toSignTransactionParams(account: ProviderAccount) throws -> SignTransactionParams {
        guard let to = self["to"] as? String,
              let from = self["from"] as? String else {
            throw EVMError.invalidParams
        }
        
        return SignTransactionParams(
            account: account,
            to: to,
            from: from,
            value: self["value"] as? String,
            gas: self["gas"] as? String,
            gasPrice: self["gasPrice"] as? String,
            data: self["data"] as? String
        )
    }
}

// MARK: - Standard Transaction Parser
func parseStandardTransactionParams(_ transaction: [String: Any]) -> [String: Any] {
    // 표준 트랜잭션 파라미터로 변환하는 로직
    // 변환이 필요 없는 경우 그대로 반환
    return transaction
}
