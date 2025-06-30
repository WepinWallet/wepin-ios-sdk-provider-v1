import Foundation
import UIKit
import WebKit
import WepinCore
import WepinModal
import WepinCommon

class WepinWebViewManager {
    // MARK: - Properties
    private var webView: WKWebView?
    private let params: WepinProviderParams
    private let wepinModal = WepinModal()
    private let baseUrl: String
    private var responseWepinUserSetDeferred: CheckedContinuation<Bool, Error>?
    //    private var _currentWepinRequest: <String, Any?>? = null
    private var responseDeferred: CheckedContinuation<String, Error>?
    
    // 요청 큐
    private var requestQueue: [WepinRequestMessage] = []
    // 요청 ID와 응답 컨티뉴에이션을 연결하는 맵
    private var responseMap: [String: CheckedContinuation<Any, Error>] = [:]
    
    // MARK: - Initialization
    init(params: WepinProviderParams, baseUrl: String) {
        self.params = params
        self.baseUrl = baseUrl
    }
    
    public func openWidget(viewController: UIViewController) {
        wepinModal.openModal(on: viewController, url: baseUrl, jsProcessor: JSProcessor.processRequest(request:webView:callback:))
    }
    
    // 요청을 큐에 추가하고 응답을 기다리는 메서드
    func enqueueRequest(_ request: WepinRequestMessage) async throws -> Any {
//        print("enqueue Request request: \(request)")
        let requestId = String(request.header.id)
        
        return try await withCheckedThrowingContinuation { continuation in
            // 응답 맵에 컨티뉴에이션 저장
            responseMap[requestId] = continuation
            // 요청 큐에 추가
            requestQueue.append(request)
        }
    }
    
    // 다음 요청을 큐에서 가져오는 메서드
    func dequeueRequest() -> [String: Any]? {
        guard !requestQueue.isEmpty else {
            return nil
        }
        
        let request = requestQueue.removeFirst()
        return request.toMap()
    }
    
    // 응답 처리 메서드
    func handleResponse(requestId: Int, response: [String: Any]) {
        // 해당 요청 ID의 컨티뉴에이션 조회
        let id = String(requestId)
        guard let continuation = responseMap[id] else {
            print("No continuation found for request ID: \(id)")
            return
        }
        
        do {
            // body 객체 추출
            guard let body = response["body"] as? [String: Any],
                  let state = body["state"] as? String else {
                throw WepinError.parsingFailed("Invalid response format")
            }
            
            switch state.uppercased() {
            case "SUCCESS":
                // 성공 시 data 반환
                if let data = body["data"] {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: true) // 데이터가 없는 경우 성공으로 간주
                }
                
            case "ERROR":
                // 오류 시 적절한 예외 발생
                let errorMessage = body["data"] as? String ?? "Unknown error"
                if errorMessage.contains("User Cancel") {
                    continuation.resume(throwing: WepinError.userCanceled)
                } else {
                    continuation.resume(throwing: WepinError.unknown(errorMessage))
                }
                
            default:
                continuation.resume(throwing: WepinError.unknown("Unknown state: \(state)"))
            }
        } catch {
            // 예외 발생 시 전달
            continuation.resume(throwing: error)
        }
        
        // 응답 맵에서 제거
        responseMap.removeValue(forKey: id)
    }
    
    // 모든 요청 정리 (closeWidget에서 호출)
    func clearRequests() {
        // 현재 대기 중인 모든 요청에 취소 오류 전달
        for (_, continuation) in responseMap {
            continuation.resume(throwing: WepinError.userCanceled)
        }
        
        // 큐와 맵 초기화
        requestQueue.removeAll()
        responseMap.removeAll()
    }
    
    func closeWidget() {
        wepinModal.closeModal()
    }
    
    // for set_local_storage 에서 유저 정보가 있는 경우 수행하기 위해
    func resetResponseWepinUserDeferred() {
        responseWepinUserSetDeferred = nil
    }
    
    func getResponseWepinUserDeferred() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            responseWepinUserSetDeferred = continuation
        }
    }
    
    func completeResponseWepinUserDeferred(success: Bool) {
        responseWepinUserSetDeferred?.resume(returning: success)
        responseWepinUserSetDeferred = nil
    }
    
    // get_sdk_request 의 request에 대한 response를 받아서 수행하기 위해
    public func setResponseDeferred() {
        responseDeferred = nil
    }
    
    public func getResponseDeferred() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.responseDeferred = continuation
        }
    }
    
    public func completeResponseDeferred(_ result: String) {
        responseDeferred?.resume(returning: result)
        responseDeferred = nil
    }
    
    public func failResponseDeferred(_ error: Error) {
        responseDeferred?.resume(throwing: error)
        responseDeferred = nil
    }
    
    func mapWebviewErrorToWepinError(_ message: String) -> WepinError {
        // 특정 문자열 매핑 예시
        if message.contains("network error") {
            return WepinError.networkError(message)
        } else if message.contains("User Cancel") {
            return WepinError.userCanceled
        } else if message.contains("Invalid App Key") {
            return WepinError.invalidAppKey
        } else if message.contains("Invalid Parameter") {
            return WepinError.invalidParameter(message)
        } else if message.contains("Invalid Login Session") {
            return WepinError.invalidLoginSession(message)
        } else if message.contains("Not Initialized") {
            return WepinError.notInitialized
        } else if message.contains("Already Initialized") {
            return WepinError.alreadyInitialized
        } else if message.contains("Failed Login") {
            return WepinError.loginFailed
        } else {
            return WepinError.unknown(message)
        }
    }
}
