// Updated EVMMethod.swift with improved error handling and readability

import Foundation

// EVM 메소드 리스트
let ethMethodList = [
    "eth_blockNumber",
    "eth_accounts",
    "eth_requestAccounts",
    "eth_getBalance",
    "eth_gasPrice",
    "eth_estimateGas",
    "eth_signTransaction",
    "eth_sendTransaction",
    "eth_call",
    "eth_sign",
    "personal_sign",
    "eth_signTypedData_v1",
    "eth_signTypedData_v3",
    "eth_signTypedData_v4"
]

// 각 메소드별 파라미터 스펙
let ethMethodParamSpecs: [String: [String: String]] = [
    "eth_sendTransaction": [
        "from": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "to": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "gas": "",
        "gasPrice": "",
        "value": "0x03e8",
        "data": ""
    ],
    "eth_signTransaction": [
        "from": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "to": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "gas": "",
        "gasPrice": "",
        "value": "0x03e8",
        "data": ""
    ],
    "personal_sign": [
        "message": "Hello, World!",
        "address": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6"
    ],
    "eth_sign": [
        "address": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "message": "Hello, World!"
    ],
    "eth_signTypedData_v1": [
        "address": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "typedData": "[]"
    ],
    "eth_signTypedData_v3": [
        "address": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "typedData": "{}"
    ],
    "eth_signTypedData_v4": [
        "address": "0x6A77d58A6eB1a2Ed8238E6F7200D64F87ca477b6",
        "typedData": "{}"
    ]
]

// JSON 예제 생성 및 처리를 위한 유틸리티 클래스
class EVMMethodHelper {
    // 연결된 계정
    static var connectedAccount: String?
    
    // 특정 메소드에 대한 JSON 예제 생성
    static func defaultJsonExample(for method: String) -> String {
        let account = connectedAccount ?? "0xabcdef1234567890abcdef1234567890abcdef12"
        
        switch method {
        case "eth_blockNumber", "eth_accounts", "eth_requestAccounts", "eth_gasPrice":
            return "[]"
            
        case "eth_getBalance":
            return """
            [
              "\(account)",
              "latest"
            ]
            """
            
        case "eth_call":
            return """
            [
              {
                "to": "\(account)",
                "data": "0xabcdef"
              },
              "latest"
            ]
            """
            
        case "eth_estimateGas":
            return """
            [
              {
                "from": "\(account)",
                "to": "\(account)",
                "data": "0xabcdef"
              }
            ]
            """
            
        case "eth_signTransaction", "eth_sendTransaction":
            return """
            [
              {
                "from": "\(account)",
                "to": "\(account)",
                "gas": "0x5208",
                "gasPrice": "0x3b9aca00",
                "value": "0x0",
                "data": "0x"
              }
            ]
            """
            
        case "eth_sign":
            return """
            [
              "\(account)",
              "0x68656c6c6f20776f726c64"
            ]
            """
            
        case "personal_sign":
            return """
            [
              "0x68656c6c6f20776f726c64",
              "\(account)"
            ]
            """
            
        case "eth_signTypedData_v1":
            return """
            [
              "\(account)",
              [
                {
                  "type": "string",
                  "name": "message",
                  "value": "Hello, world!"
                }
              ]
            ]
            """
            
        case "eth_signTypedData_v3", "eth_signTypedData_v4":
            return """
            [
              "\(account)",
              {
                "types": {
                  "EIP712Domain": [
                    { "name": "name", "type": "string" },
                    { "name": "version", "type": "string" },
                    { "name": "chainId", "type": "uint256" },
                    { "name": "verifyingContract", "type": "address" }
                  ],
                  "Mail": [
                    { "name": "from", "type": "Person" },
                    { "name": "to", "type": "Person" },
                    { "name": "contents", "type": "string" }
                  ],
                  "Person": [
                    { "name": "name", "type": "string" },
                    { "name": "wallet", "type": "address" }
                  ]
                },
                "primaryType": "Mail",
                "domain": {
                  "name": "Ether Mail",
                  "version": "1",
                  "chainId": 1,
                  "verifyingContract": "\(account)"
                },
                "message": {
                  "from": {
                    "name": "Alice",
                    "wallet": "\(account)"
                  },
                  "to": {
                    "name": "Bob",
                    "wallet": "\(account)"
                  },
                  "contents": "Hello, Bob!"
                }
              }
            ]
            """
            
        default:
            return "[]"
        }
    }
    
    // JSON 문자열을 Any 타입의 배열로 변환
    static func parseJsonToParams(_ jsonString: String) -> [Any]? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return nil
        }
        
        do {
            guard let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [Any] else {
                print("Failed to parse JSON as array")
                return nil
            }
            return jsonArray
        } catch {
            print("JSON 파싱 오류: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 딕셔너리를 JSON 문자열로 변환 (디버깅 용도)
    static func dictToJsonString(_ dict: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to convert dictionary to JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 계정 정보 업데이트
    static func updateConnectedAccount(_ account: String) {
        connectedAccount = account
    }
}
