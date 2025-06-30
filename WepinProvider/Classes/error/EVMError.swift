import Foundation
import WepinCommon

enum EVMError: Error, LocalizedError {
    // Provider 에러 (EIP-1193)
    case userRejectedRequest          // 4001
    case unauthorized                 // 4100
    case unsupportedMethod            // 4200
    case disconnected                 // 4900
    case chainDisconnected            // 4901
    
    // JSON-RPC 에러 (EIP-1474)
    case parseError                   // -32700
    case invalidRequest               // -32600
    case methodNotFound               // -32601
    case invalidParams                // -32602
    case internalError                // -32603
    
    // 트랜잭션 관련 에러
    case invalidInput                 // -32000
    case resourceNotFound             // -32001
    case resourceUnavailable          // -32002
    case transactionRejected          // -32003
    case methodNotSupported           // -32004
    case requestLimitExceeded         // -32005
    case jsonRpcVersionNotSupported   // -32006
    
    // 기존 iOS 전용 에러
    case notInitialized
    case unknown(String)
    
    // 오류 코드
    var code: Int {
        switch self {
        // Provider 에러 (EIP-1193)
        case .userRejectedRequest:         return 4001
        case .unauthorized:                return 4100
        case .unsupportedMethod:           return 4200
        case .disconnected:                return 4900
        case .chainDisconnected:           return 4901
            
        // JSON-RPC 에러 (EIP-1474)
        case .parseError:                  return -32700
        case .invalidRequest:              return -32600
        case .methodNotFound:              return -32601
        case .invalidParams:               return -32602
        case .internalError:               return -32603
            
        // 트랜잭션 관련 에러
        case .invalidInput:                return -32000
        case .resourceNotFound:            return -32001
        case .resourceUnavailable:         return -32002
        case .transactionRejected:         return -32003
        case .methodNotSupported:          return -32004
        case .requestLimitExceeded:        return -32005
        case .jsonRpcVersionNotSupported:  return -32006
            
        // 기존 iOS 전용 에러
        case .notInitialized:              return -40000
        case .unknown:                     return -40001
        }
    }
    
    // 오류 메시지
    var message: String {
        switch self {
        // Provider 에러 (EIP-1193)
        case .userRejectedRequest:
            return "User rejected the request"
        case .unauthorized:
            return "The requested method and/or account has not been authorized by the user"
        case .unsupportedMethod:
            return "The Provider does not support the requested method"
        case .disconnected:
            return "The Provider is disconnected from all chains"
        case .chainDisconnected:
            return "The Provider is not connected to the requested chain"
            
        // JSON-RPC 에러 (EIP-1474)
        case .parseError:
            return "Invalid JSON was received by the server"
        case .invalidRequest:
            return "The JSON sent is not a valid Request object"
        case .methodNotFound:
            return "The method does not exist / is not available"
        case .invalidParams:
            return "Invalid method parameter(s)"
        case .internalError:
            return "Internal JSON-RPC error"
            
        // 트랜잭션 관련 에러
        case .invalidInput:
            return "Missing or invalid parameters"
        case .resourceNotFound:
            return "Requested resource not found"
        case .resourceUnavailable:
            return "Requested resource not available"
        case .transactionRejected:
            return "Transaction creation failed"
        case .methodNotSupported:
            return "Method is not implemented"
        case .requestLimitExceeded:
            return "Request exceeds defined limit"
        case .jsonRpcVersionNotSupported:
            return "Version of JSON-RPC protocol not supported"
            
        // 기존 iOS 전용 에러
        case .notInitialized:
            return "Provider is not initialized"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    // LocalizedError 프로토콜 구현
    var errorDescription: String? {
        return message
    }
    
    // 추가 오류 정보 제공
    var failureReason: String? {
        switch self {
        case .userRejectedRequest:
            return "The user declined the request in their wallet or interface."
        case .unauthorized:
            return "The user has not approved this app or the account is not available."
        case .chainDisconnected:
            return "The current account's network does not match the requested network."
        case .invalidParams:
            return "The parameters provided to the method were invalid or incomplete."
        default:
            return message
        }
    }
    
    // 오류 복구 제안
    var recoverySuggestion: String? {
        switch self {
        case .userRejectedRequest:
            return "Please try again and approve the request in your wallet."
        case .unauthorized:
            return "Please connect your wallet and authorize this application."
        case .chainDisconnected:
            return "Please switch to the correct network in your wallet."
        case .notInitialized:
            return "Please initialize the provider before making requests."
        case .invalidParams:
            return "Please check your input parameters and try again."
        default:
            return nil
        }
    }
}

// 오류 변환 헬퍼
extension EVMError {
    static func fromCode(_ code: Int, message: String? = nil) -> EVMError {
        switch code {
        // Provider 에러 (EIP-1193)
        case 4001: return .userRejectedRequest
        case 4100: return .unauthorized
        case 4200: return .unsupportedMethod
        case 4900: return .disconnected
        case 4901: return .chainDisconnected
            
        // JSON-RPC 에러 (EIP-1474)
        case -32700: return .parseError
        case -32600: return .invalidRequest
        case -32601: return .methodNotFound
        case -32602: return .invalidParams
        case -32603: return .internalError
            
        // 트랜잭션 관련 에러
        case -32000: return .invalidInput
        case -32001: return .resourceNotFound
        case -32002: return .resourceUnavailable
        case -32003: return .transactionRejected
        case -32004: return .methodNotSupported
        case -32005: return .requestLimitExceeded
        case -32006: return .jsonRpcVersionNotSupported
            
        // 기존 iOS 전용 에러
        case -40000: return .notInitialized
        default: return .unknown(message ?? "Error code: \(code)")
        }
    }
}

class ErrorMapper {
    static func mapToEthRpcError(_ error: Error) -> [String: Any] {
        // EVMError가 이미 완벽하게 정의되어 있으므로 이를 활용
        if let evmError = error as? EVMError {
            return [
                "code": evmError.code,
                "message": evmError.message
            ]
        }
        
        // 기본 에러
        return [
            "code": EVMError.internalError.code,
            "message": error.localizedDescription
        ]
    }
    
    private static func mapErrorCodeToEVMError(_ code: String, message: String) -> EVMError {
        switch code {
        case "UserCancelled":
            return .userRejectedRequest
        case "NotInitialized":
            return .notInitialized
        case "InvalidParameters":
            return .invalidParams
        case "Unauthorized":
            return .unauthorized
        case "UnsupportedNetwork":
            return .chainDisconnected
        case "InsufficientFunds":
            return .invalidInput
        case "RequestFailed":
            return .internalError
        default:
            return .unknown(message)
        }
    }
}
