import Foundation
import WepinCore

/// RPC 메서드 핸들러 클래스
class RpcMethodHandler {
    private let rpc: JsonRpcUrl
    private let jsonRpcClient: JsonRpcClient
    
    init(rpc: JsonRpcUrl) {
        self.rpc = rpc
        self.jsonRpcClient = WepinCore.shared.createJsonRpcClient(rpc: rpc)
    }
    
    /// RPC 요청을 보내는 메서드
    /// - Parameters:
    ///   - method: 호출할 RPC 메서드 이름
    ///   - params: 메서드에 전달할 파라미터
    /// - Returns: 호출 결과
    func send(method: String, params: [Any]?) async throws -> Any {
        print("RpcMethodHandler - params: \(String(describing: params))")
        return try await jsonRpcClient.call(method, params)
    }
}
