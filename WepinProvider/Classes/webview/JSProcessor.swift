import Foundation
import WepinLogin
import WebKit
import WepinCommon
import WepinCore

struct Command {
    static let CMD_READY_TO_WIDGET = "ready_to_widget"
    static let CMD_CLOSE_WEPIN_WIDGET = "close_wepin_widget"
    static let CMD_SET_LOCAL_STORAGE = "set_local_storage"
    
    static let CMD_DEQUEUE_REQUEST = "dequeue_request"
    static let CMD_REQUEST_INFO = "request_info"
    
    static let CMD_REQUEST_ENABLE = "request_enable"
    static let CMD_SIGN_TRANSACTION = "sign_transaction"
    static let CMD_SEND_TRANSACTION = "send_transaction"
    static let CMD_SIGN = "sign"
    static let CMD_SIGN_TYPED_DATA = "sign_typed_data"
    static let CMD_WALLET_SWITCH_ETHEREUM_CHAIN = "wallet_switchEthereumChain"
    static let CMD_SIGN_ALL_TRANSACTIONS = "sign_all_transactions"
    
    private static let responseCommands: Set<String> = [
        CMD_REQUEST_ENABLE,
        CMD_SIGN_TRANSACTION,
        CMD_SEND_TRANSACTION,
        CMD_SIGN,
        CMD_SIGN_TYPED_DATA,
        CMD_WALLET_SWITCH_ETHEREUM_CHAIN,
        CMD_SIGN_ALL_TRANSACTIONS
    ]
    
    static func isResponseCommand(command: String) -> Bool {
        return responseCommands.contains(command)
    }
}

struct State {
    // Commands for JS processor
    static let STATE_SUCCESS = "SUCCESS"
    static let STATE_ERROR = "ERROR"
}


class JSProcessor {
    static func processRequest(request: String, webView: WKWebView, callback: @escaping (String) -> Void) {
//        print("processRequest")
//        print("request: \(request)")
        do {
            let jsonData = request.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            let headerObject = jsonObject["header"] as! [String: Any]
            let bodyObject = jsonObject["body"] as! [String: Any]
            let command = bodyObject["command"] as! String
            var jsResponse: JSResponse? = nil
            
            var id: Int = -1
            var requestFrom: String = ""
            
            if Command.isResponseCommand(command: command) {
                guard let headerId = headerObject["id"] as? Int,
                      let _ = headerObject["response_to"] as? String,
                      let responseFrom = headerObject["response_from"] as? String else {
                    print("Invalid message format for response command: missing required fields")
                    return
                }
                id = headerId
                requestFrom = responseFrom
            } else {
                guard let headerId = headerObject["id"] as? Int,
                      let _ = headerObject["request_to"] as? String,
                      let requestFromValue = headerObject["request_from"] as? String else {
                    print("Invalid message format for request command: missing required fields")
                    return
                }
                id = headerId
                requestFrom = requestFromValue
            }
            
            
            switch command {
            case Command.CMD_READY_TO_WIDGET:
                print("CMD_READY_TO_WIDGET")
                let appKey = WepinProviderManager.shared.appKey
                let appId = WepinProviderManager.shared.appId
                let domain = WepinProviderManager.shared.domain
                let platform = 3 // ios: 3
                let type = WepinProviderManager.shared.sdkType
                let version = WepinProviderManager.shared.version
                let attributes = WepinProviderManager.shared.wepinAttributes
                let storageData = WepinCore.shared.storage.getAllStorage()
                jsResponse = JSResponse.Builder(
                    id: "\(id)",
                    requestFrom: requestFrom,
                    command: command,
                    state: State.STATE_SUCCESS
                ).setBodyData(parameter: JSResponse.Builder.ReadyToWidgetBodyData(
                    appKey: appKey,
                    appId: appId,
                    domain: domain,
                    platform: platform,
                    type: type,
                    version: version,
                    localData: convertToAnyCodableDictionary(storageData),
                    attributes: attributes
                ).toDictionary()).build()
            case Command.CMD_SET_LOCAL_STORAGE:
                print("CMD_SET_LOCAL_STORAGE")
                do {
                    guard let paramObject = bodyObject["parameter"] as? [String: Any],
                          let dataObject = paramObject["data"] as? [String: Any] else {
                        print("Invalid parameter format")
                        return
                    }
                    
                    var storageDataMap: [String: Codable] = [:]
                    // 데이터 처리 로직 구현
                    for (key, value) in dataObject {
                        let storageValue: Codable
                        if let jsonObject = value as? [String: Any] {
                            // Dictionary를 JSON String으로 변환
                            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                storageValue = jsonString
                            } else {
                                throw NSError(domain: "JSONSerialization", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to String"])
                            }
                        } else if let stringValue = value as? String {
                            // String 값 처리
                            storageValue = stringValue
                        } else if let intValue = value as? Int {
                            // Int 값 처리
                            storageValue = intValue
                        } else {
                            // 지원되지 않는 데이터 타입 예외 처리
                            throw NSError(domain: "UnsupportedDataType", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported data type for key: \(key)"])
                        }
                        // 처리된 값을 storageDataMap에 추가
                        storageDataMap[key] = storageValue
                    }
                    
                    WepinCore.shared.storage.setAllStorage(data: storageDataMap)
                    if storageDataMap["user_info"] != nil {
                        WepinProviderManager.shared.wepinWebViewManager?.completeResponseWepinUserDeferred(success: true)
                    }
                    jsResponse = JSResponse.Builder(
                        id: "\(id)",
                        requestFrom: requestFrom,
                        command: command,
                        state: State.STATE_SUCCESS
                    ).build()
                    
                } catch {
                    print("Error processing JSON data: \(error.localizedDescription)")
                    //                    throw WepinError.generalUnKnownEx(error.localizedDescription)
                }
                
            case Command.CMD_CLOSE_WEPIN_WIDGET:
                print("CMD_CLOSE_WEPIN_WIDGET")
                jsResponse = nil
                WepinProviderManager.shared.wepinWebViewManager?.closeWidget()
                
            case Command.CMD_DEQUEUE_REQUEST:
                print("CMD_DEQUEUE_REQUEST")
                let originalBody = WepinProviderManager.shared.getWepinRequest()
                    
                    // 구조체 처리
                    let processedBody = processWepinRequest(originalBody)
                jsResponse = JSResponse.Builder(id: "\(id)", requestFrom: requestFrom, command: command, state: State.STATE_SUCCESS).setBodyData(
                    parameter: processedBody != nil ? convertToAnyCodable(processedBody!) : AnyCodable("No request")
                ).build()
                
            case Command.CMD_REQUEST_ENABLE,
                Command.CMD_SIGN_TRANSACTION,
                Command.CMD_SEND_TRANSACTION,
                Command.CMD_SIGN,
                Command.CMD_SIGN_TYPED_DATA,
                Command.CMD_WALLET_SWITCH_ETHEREUM_CHAIN,
                Command.CMD_SIGN_ALL_TRANSACTIONS :
                print("\(command)")
                WepinProviderManager.shared.wepinWebViewManager?.handleResponse(requestId: id, response: jsonObject)
                //                WepinProviderManager.shared.wepinWebViewManager?.completeResponseDeferred(request)
            default:
                print("JSProcessor Response is null")
                return
            }
            // 7. JSResponse가 nil이 아닌 경우 JSON으로 변환하여 출력
            if let jsResponse = jsResponse {
                do {
                    let responseData = try JSONEncoder().encode(jsResponse)
                    if let responseString = String(data: responseData, encoding: .utf8) {
//                        print("JSProcessor Response: \(responseString)")
                        
                        // 웹뷰가 존재하는지 안전하게 체크
                        //                        guard let webView = webView else {
                        //                            print("Error: WebView is nil")
                        //
                        //                            return
                        //                        }
                        
                        // 웹뷰로 응답 전송
                        sendResponseToWebView(response: responseString, webView: webView)
                        
                    }
                } catch {
                    print("Error encoding JSResponse: \(error.localizedDescription)")
                }
            } else {
                print("Error: jsResponse is nil")
            }
            
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
    
    // 웹뷰에 응답하는 함수
    private static func sendResponseToWebView(response: String, webView: WKWebView) {
        // JavaScript 실행을 통해 웹뷰로 응답을 전송
        //        print("response: \(response)")
        DispatchQueue.main.async {
            let message = "onResponse(" + response + ");"
            webView.evaluateJavaScript(message) { (result, error) in
                if let error = error {
                    print("Error executing JS command: \(error.localizedDescription)")
                }
            }
        }
    }
    
}

func convertToAnyCodable(_ value: Any) -> AnyCodable {
    if let dict = value as? [String: Any] {
        return AnyCodable(convertToAnyCodableDictionary(dict))
    } else if let array = value as? [Any] {
        return AnyCodable(array.map { convertToAnyCodable($0) })
    } else {
        return AnyCodable(value)
    }
}

func processWepinRequest(_ body: Any?) -> Any? {
    guard let body = body else { return nil }
    
    // body가 Dictionary 형태인 경우
    if var bodyDict = body as? [String: Any],
       var bodyInner = bodyDict["body"] as? [String: Any] {
        
        // parameter가 구조체인 경우 처리
        if let parameter = bodyInner["parameter"] {
            if let requestEnableParams = parameter as? RequestEnableParams {
                // RequestEnableParams 구조체를 Dictionary로 변환
                bodyInner["parameter"] = requestEnableParams.toDictionary()
            } else if let signParams = parameter as? SignParams {
                // SignParams 구조체를 Dictionary로 변환
                bodyInner["parameter"] = signParams.toDictionary()
            } else if let signTransactionParams = parameter as? SignTransactionParams {
                // SignTransactionParams 구조체를 Dictionary로 변환
                bodyInner["parameter"] = signTransactionParams.toDictionary()
            } else if let signTypedDataParams = parameter as? SignTypedDataParams {
                // SignTypedDataParams 구조체를 Dictionary로 변환
                bodyInner["parameter"] = signTypedDataParams.toDictionary()
            } else if let switchEthChainParams = parameter as? SwitchEthChainParams {
                // SwitchEthChainParams 구조체를 Dictionary로 변환
                bodyInner["parameter"] = switchEthChainParams.toDictionary()
            }
            
            // 수정된 body 반영
            bodyDict["body"] = bodyInner
            return bodyDict
        }
    }
    
    // 원본 body 반환
    return body
}

func convertToAnyCodableDictionary(_ dictionary: [String: Any]) -> [String: AnyCodable] {
    var result: [String: AnyCodable] = [:]
    for (key, value) in dictionary {
        result[key] = convertToAnyCodable(value)
    }
    return result
}

func convertJsonToLocalStorageData(_ jsonString: String) -> Any? {
    // JSON 문자열을 Data로 변환
    guard let jsonData = jsonString.data(using: .utf8) else {
        print("Failed to convert JSON string to Data")
        return nil
    }
    
    // JSON 데이터 파싱
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        return jsonObject
    } catch {
        print("Error parsing JSON data: \(error.localizedDescription)")
        return nil
    }
}


extension WepinLoginResult {
    func toDictionary() -> [String: AnyCodable] {
        return [
            "provider": AnyCodable(provider.rawValue),
            "token": AnyCodable(token.toDictionary())
        ]
    }
}

extension WepinFBToken {
    func toDictionary() -> [String: AnyCodable] {
        var result: [String: AnyCodable] = [:]
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let key = child.label {
                result[key] = AnyCodable(child.value)
            }
        }
        return result
    }
}
