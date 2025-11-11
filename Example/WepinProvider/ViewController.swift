// Updated ViewController.swift with improved code organization and completed sendRequest functionality

import UIKit
import WepinLogin
import WepinProvider // WepinProviderManager가 포함된 모듈

class ViewController: UIViewController {
    // MARK: - Properties
    
    // WepinProvider 인스턴스 및 설정값들
    var wepinProvider: WepinProvider?
    var provider: BaseProvider?
    var selectedLanguage: String = "en"
    
    var selectedMethod: String?
    var methodParamFields: [UITextField] = []
    
    var appId: String = "WEPIN_APP_ID"
    var appKey: String = "WEPIN_APP_KEY"
    
    // Login Provider 정보
    let providerInfos: [LoginProviderInfo] = [
        LoginProviderInfo(provider: "google", clientId: "GOOGLE_CLIENT_ID"),
        LoginProviderInfo(provider: "apple", clientId: "APPLE_CLIENT_ID"),
        LoginProviderInfo(provider: "discord", clientId: "DISCORD_CLIENT_ID"),
        LoginProviderInfo(provider: "naver", clientId: "NAVER_CLIENT_ID"),
        LoginProviderInfo(provider: "facebook", clientId: "FACEBOOK_CLIENT_ID"),
        LoginProviderInfo(provider: "line", clientId: "LINE_CLIENT_ID")
    ]
    
    // UI Components
    var lifecycleView: UILabel!
    var lifecycleIndicator: UIActivityIndicatorView!
    var scrollView: UIScrollView!
    var stackView: UIStackView!
    var settingsContainerView: UIView!
    var statusLabel: UILabel!
    var appIdTextField: UITextField!
    var appKeyTextField: UITextField!
    var languageSegmentedControl: UISegmentedControl!
    
    var allButtons: [UIButton] = []
    
    // 상태 및 계정 선택 관련 변수
    var settingsIsVisible: Bool = false
    var currentActionType: ActionType? = nil
    
    enum ActionType {
        case send, receive
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        initializeWepinProvider()
    }
    
    // MARK: - Setup Functions
    
    private func initializeWepinProvider() {
        let params = WepinProviderParams(appId: appId, appKey: appKey)
        do {
            wepinProvider = try WepinProvider(params)
        } catch {
            updateStatus("WepinWidget init error: \(error.localizedDescription)")
        }
    }
    
    func setupUI() {
        setupContainers()
    }
    
    private func setupContainers() {
        // 상단 영역: 버튼 및 설정 패널이 포함된 스크롤 가능한 컨테이너 (화면의 50% 차지)
        let topContainer = UIView()
        topContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topContainer)
        
        // 하단 영역: 상태 레이블이 위치할 컨테이너
        let bottomContainer = UIView()
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)
        
        NSLayoutConstraint.activate([
            // 상단 영역: safeArea의 top부터 view의 50% 높이까지
            topContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // 하단 영역: 상단 컨테이너 바로 아래부터 safeArea의 bottom까지
            bottomContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        setupTopContainer(topContainer)
        setupBottomContainer(bottomContainer)
    }
    
    private func setupTopContainer(_ container: UIView) {
        let topFixedStack = UIStackView()
        topFixedStack.axis = .vertical
        topFixedStack.spacing = 8
        topFixedStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(topFixedStack)
        
        NSLayoutConstraint.activate([
            topFixedStack.topAnchor.constraint(equalTo: container.topAnchor),
            topFixedStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topFixedStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        
        // 타이틀 레이블
        let titleLabel = UILabel()
        titleLabel.text = "Wepin Provider Test"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        topFixedStack.addArrangedSubview(titleLabel)
        
        // 상단 컨테이너 내부에 스크롤뷰 추가
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topFixedStack.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // 스크롤뷰 내에 버튼 및 설정 패널을 담을 스택뷰 추가
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        setupSettingsPanel()
        addFunctionButtons()
    }
    
    private func setupSettingsPanel() {
        // 설정 패널 토글 버튼
        let toggleSettingsButton = createButton(title: "Open Settings", action: #selector(toggleSettings(_:)))
        stackView.addArrangedSubview(toggleSettingsButton)
        
        // 설정 패널 뷰
        settingsContainerView = UIView()
        settingsContainerView.backgroundColor = .systemGray6
        settingsContainerView.layer.cornerRadius = 8
        settingsContainerView.layer.shadowColor = UIColor.black.cgColor
        settingsContainerView.layer.shadowOpacity = 0.2
        settingsContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        settingsContainerView.isHidden = true
        settingsContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        let settingsStack = UIStackView()
        settingsStack.axis = .vertical
        settingsStack.spacing = 8
        settingsStack.translatesAutoresizingMaskIntoConstraints = false
        settingsContainerView.addSubview(settingsStack)
        NSLayoutConstraint.activate([
            settingsStack.topAnchor.constraint(equalTo: settingsContainerView.topAnchor, constant: 16),
            settingsStack.leadingAnchor.constraint(equalTo: settingsContainerView.leadingAnchor, constant: 16),
            settingsStack.trailingAnchor.constraint(equalTo: settingsContainerView.trailingAnchor, constant: -16),
            settingsStack.bottomAnchor.constraint(equalTo: settingsContainerView.bottomAnchor, constant: -16)
        ])
        
        let settingsTitle = UILabel()
        settingsTitle.text = "Settings"
        settingsTitle.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        settingsStack.addArrangedSubview(settingsTitle)
        
        let appIdLabel = UILabel()
        appIdLabel.text = "App ID"
        settingsStack.addArrangedSubview(appIdLabel)
        
        appIdTextField = UITextField()
        appIdTextField.borderStyle = .roundedRect
        appIdTextField.text = appId
        settingsStack.addArrangedSubview(appIdTextField)
        
        let appKeyLabel = UILabel()
        appKeyLabel.text = "App Key"
        settingsStack.addArrangedSubview(appKeyLabel)
        
        appKeyTextField = UITextField()
        appKeyTextField.borderStyle = .roundedRect
        appKeyTextField.text = appKey
        settingsStack.addArrangedSubview(appKeyTextField)
        
        let applyChangesButton = UIButton(type: .system)
        applyChangesButton.setTitle("Apply Changes", for: .normal)
        applyChangesButton.addTarget(self, action: #selector(applySettings), for: .touchUpInside)
        settingsStack.addArrangedSubview(applyChangesButton)
        
        stackView.addArrangedSubview(settingsContainerView)
    }
    
    private func setupBottomContainer(_ container: UIView) {
        let textWrapperScrollView = UIScrollView()
        textWrapperScrollView.translatesAutoresizingMaskIntoConstraints = false
        textWrapperScrollView.layer.borderColor = UIColor.lightGray.cgColor
        textWrapperScrollView.layer.borderWidth = 1
        textWrapperScrollView.layer.cornerRadius = 8
        textWrapperScrollView.clipsToBounds = true
        container.addSubview(textWrapperScrollView)
        
        // 상태 레이블
        statusLabel = UILabel()
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .left
        statusLabel.textColor = .black
        statusLabel.text = "Status: Not Initialized"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        textWrapperScrollView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            // ScrollView Constraints
            textWrapperScrollView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            textWrapperScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            textWrapperScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            textWrapperScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            
            // Label Constraints (ScrollView Content)
            statusLabel.topAnchor.constraint(equalTo: textWrapperScrollView.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: textWrapperScrollView.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: textWrapperScrollView.trailingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: textWrapperScrollView.bottomAnchor, constant: -8),
            statusLabel.widthAnchor.constraint(equalTo: textWrapperScrollView.widthAnchor, constant: -16)
        ])
    }
    
    func addFunctionButtons() {
        // 기능 버튼 추가
        let initializeButton = createButton(title: "Initialize", action: #selector(initializeTapped))
        stackView.addArrangedSubview(initializeButton)
        
        let checkStatusButton = createButton(title: "Check Initialization Status", action: #selector(checkInitStatusTapped))
        stackView.addArrangedSubview(checkStatusButton)
        
        let loginButton = createButton(title: "Login", action: #selector(loginTapped))
        stackView.addArrangedSubview(loginButton)
        
        let logoutButton = createButton(title: "Logout", action: #selector(logoutTapped))
        stackView.addArrangedSubview(logoutButton)
        
        let getUserButton = createButton(title: "Get Wepin User", action: #selector(getWepinUserTapped))
        stackView.addArrangedSubview(getUserButton)
        
        let getProviderButton = createButton(title: "GetProvider(Oasys Testnet)", action: #selector(getProviderTapped))
        stackView.addArrangedSubview(getProviderButton)
        
        let sendRequestButton = createButton(title: "Send Request", action: #selector(sendRequestTapped))
        stackView.addArrangedSubview(sendRequestButton)
        
        let switchChainButton = createButton(title: "switchChain", action: #selector(switchChainTapped))
        stackView.addArrangedSubview(switchChainButton)
        
        let finalizeButton = createButton(title: "Finalize", action: #selector(finalizeTapped))
        stackView.addArrangedSubview(finalizeButton)
    }
    
    func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = 8
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        allButtons.append(button)
        return button
    }
    
    // MARK: - Action Methods
    
    @objc func toggleSettings(_ sender: UIButton) {
        settingsIsVisible.toggle()
        settingsContainerView.isHidden = !settingsIsVisible
        let newTitle = settingsIsVisible ? "Close Settings" : "Open Settings"
        sender.setTitle(newTitle, for: .normal)
    }
    
    @objc func applySettings() {
        // 텍스트필드의 값으로 설정값 갱신
        appId = appIdTextField.text ?? appId
        appKey = appKeyTextField.text ?? appKey
        
        // WepinProvider 재생성
        let providerParams = WepinProviderParams(appId: appId, appKey: appKey)
        wepinProvider = WepinProvider(providerParams)
        
        updateStatus("Settings Applied")
    }
    
    @objc func initializeTapped() {
        Task {
            guard let provider = wepinProvider else {
                updateStatus("wepinLogin is nil. Apply settings first.")
                return
            }
            do {
                let result = try await provider.initialize(attributes: WepinProviderAttributes(defaultLanguage: "ko", defaultCurrency: "KRW"))
                updateStatus(result ? "Initialized" : "Initialization Failed")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func checkInitStatusTapped() {
        if let provider = wepinProvider, provider.isInitialized() {
            updateStatus("WepinProvider is Initialized")
        } else {
            updateStatus("Not Initialized")
        }
    }
    
    @objc func loginTapped() {
        // 로그인 화면 표시 AlertController
        let alert = UIAlertController(title: "Login Method", message: "Choose login method", preferredStyle: .actionSheet)
        
        // 이메일 로그인
        let emailAction = UIAlertAction(title: "Email Login", style: .default) { [weak self] _ in
            self?.showEmailLoginScreen()
        }
        alert.addAction(emailAction)
        
        // OAuth 로그인 옵션들
        let googleAction = UIAlertAction(title: "Google Login", style: .default) { [weak self] _ in
            self?.loginWithGoogleTapped()
        }
        alert.addAction(googleAction)
        
        let appleAction = UIAlertAction(title: "Apple Login", style: .default) { [weak self] _ in
            self?.loginWithAppleTapped()
        }
        alert.addAction(appleAction)
        
        let discordAction = UIAlertAction(title: "Discord Login", style: .default) { [weak self] _ in
            self?.loginWithDiscordTapped()
        }
        alert.addAction(discordAction)
        
        let naverAction = UIAlertAction(title: "Naver Login", style: .default) { [weak self] _ in
            self?.loginWithNaverTapped()
        }
        alert.addAction(naverAction)
        
        let facebookAction = UIAlertAction(title: "Facebook Login", style: .default) { [weak self] _ in
            self?.loginWithFacebookTapped()
        }
        alert.addAction(facebookAction)
        
        let lineAction = UIAlertAction(title: "Line Login", style: .default) { [weak self] _ in
            self?.loginWithLineTapped()
        }
        alert.addAction(lineAction)
        
        let kakaoAction = UIAlertAction(title: "Kakao Login", style: .default) { [weak self] _ in
            self?.loginWithKakaoTapped()
        }
        alert.addAction(kakaoAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc func logoutTapped() {
        Task {
            guard let provider = wepinProvider, let login = provider.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            do {
                let result = try await login.logoutWepin()
                updateStatus("\(result)")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func getWepinUserTapped() {
        Task {
            guard let login = wepinProvider?.login else {
                updateStatus("wepnLogin is nil")
                return
            }
            do {
                let result = try await login.getCurrentWepinUser()
                updateStatus("\(result)")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func getProviderTapped() {
        guard let wepinProvider = wepinProvider, wepinProvider.isInitialized() else {
            updateStatus("WepinProvider is not initialized")
            return
        }
        
        do {
            // Oasys Testnet 프로바이더 가져오기
            provider = try wepinProvider.getProvider(network: "evmoasys-games-testnet")
            if provider != nil {
                updateStatus("evmoasys-games-testnet provider obtained!")
            } else {
                updateStatus("Failed to get provider")
            }
        } catch {
            updateStatus("Error: \(error.localizedDescription)")
        }
    }
    
    @objc func sendRequestTapped() {
        if provider == nil {
            updateStatus("Provider is nil. Get provider first.")
            return
        }
        
        // 메소드 리스트 화면 표시
        showMethodListScreen()
    }
    
    @objc func switchChainTapped() {
        if provider == nil {
            updateStatus("Provider is nil. Get provider first.")
            return
        }
        
        let params: [Any] = [["chainId": "0x01"]]
        Task {
            do {
                let result = try await provider?.request(method: "wallet_switchEthereumChain", params: params)
                DispatchQueue.main.async {
                    self.updateStatus("Switch chain result: \(result ?? "nil")")
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Switch chain error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func finalizeTapped() {
        Task {
            guard let provider = wepinProvider else {
                updateStatus("WepinProvider is nil.")
                return
            }
            provider.finalize()
            updateStatus("Finalized")
        }
    }
    
    // MARK: - OAuth Login Methods
    
    @objc func loginWithGoogleTapped() {
        loginWithOauthProvider(providerName: "google")
    }
    
    @objc func loginWithAppleTapped() {
        loginWithOauthProvider(providerName: "apple")
    }
    
    @objc func loginWithDiscordTapped() {
        loginWithOauthProvider(providerName: "discord")
    }
    
    @objc func loginWithNaverTapped() {
        loginWithOauthProvider(providerName: "naver")
    }
    
    @objc func loginWithFacebookTapped() {
        loginWithOauthProvider(providerName: "facebook")
    }
    
    @objc func loginWithLineTapped() {
        loginWithOauthProvider(providerName: "line")
    }
    
    @objc func loginWithKakaoTapped() {
        loginWithOauthProvider(providerName: "kakao")
    }
    
    // MARK: - Login Helpers
    
    func showEmailLoginScreen() {
        // 이메일 로그인 화면 AlertController
        let alert = UIAlertController(title: "Email Login", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        let loginAction = UIAlertAction(title: "Login", style: .default) { [weak self, weak alert] _ in
            guard let email = alert?.textFields?[0].text, let password = alert?.textFields?[1].text else {
                return
            }
            
            // 비동기 함수를 Task 내에서 호출하여 오류 해결
            Task {
                await self?.loginWithEmail(email: email, password: password)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(loginAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func loginWithEmail(email: String, password: String) async {
        guard let login = wepinProvider?.login else {
            updateStatus("wepnLogin is nil")
            return
        }
        do {
            let params = WepinLoginWithEmailParams(email: email, password: password)
            let result = try await login.loginWithEmailAndPassword(params: params)
            updateStatus("loginWithEmail: \(result)")
            wepinLogin(loginResult: result)
        } catch {
            updateStatus("Error: \(error.localizedDescription)")
        }
    }
    
    private func loginWithOauthProvider(providerName: String) {
        Task {
            guard let provider = wepinProvider, let login = provider.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            
            do {
                if (!login.isInitialized()) {
                    updateStatus("login initialize failed")
                    return
                }
                let providerInfo = providerInfos.first(where: { $0.provider == providerName })
                let params = WepinLoginOauth2Params(provider: providerInfo?.provider ?? "", clientId: providerInfo?.clientId ?? "")
                let result = try await login.loginWithOauthProvider(params: params, viewController: self)
                updateStatus("loginWithOauthProvider: \(result)")
                switch(result.type) {
                case WepinOauthTokenType.idToken:
                    self.loginWithIdToken(idToken: result.token)
                case WepinOauthTokenType.accessToken:
                    self.loginWithAccessToken(providerName: providerName, accessToken: result.token)
                }
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func loginWithIdToken(idToken: String) {
        Task {
            guard let provider = wepinProvider, let login = provider.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            let params = WepinLoginOauthIdTokenRequest(idToken: idToken)
            do {
                let result = try await login.loginWithIdToken(params: params)
                updateStatus("loginWithIdToken: \(result)")
                self.wepinLogin(loginResult: result)
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func loginWithAccessToken(providerName: String, accessToken: String) {
        Task {
            guard let provider = wepinProvider, let login = provider.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            let params = WepinLoginOauthAccessTokenRequest(provider: providerName, accessToken: accessToken)
            do {
                let result = try await login.loginWithAccessToken(params: params)
                updateStatus("loginWithAccessToken: \(result)")
                self.wepinLogin(loginResult: result)
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func wepinLogin(loginResult: WepinLoginResult) {
        Task {
            guard let provider = wepinProvider, let login = provider.login else {
                updateStatus("wepinLogin is nil")
                return
            }
            do {
                let result = try await login.loginWepin(params: loginResult)
                updateStatus("wepinLogin: \(result)")
            } catch {
                updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - EVM Method Handlers
    
    func showMethodListScreen() {
        let alert = UIAlertController(title: "EVM Method List", message: "Select a method to call", preferredStyle: .actionSheet)
        
        for method in ethMethodList {
            let action = UIAlertAction(title: method, style: .default) { [weak self] _ in
                self?.selectedMethod = method
                self?.showMethodParamsScreen(method: method)
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func showMethodParamsScreen(method: String) {
        // 메소드 파라미터 입력 화면
        let alert = UIAlertController(title: "Enter Parameters for \(method)", message: nil, preferredStyle: .alert)
        
        // 기존 필드 클리어
        methodParamFields.removeAll()
        
        if let params = ethMethodParamSpecs[method] {
            // 파라미터 스펙이 있는 경우 각 파라미터에 대한 텍스트필드 추가
            for (key, defaultValue) in params {
                alert.addTextField { textField in
                    textField.placeholder = key
                    textField.text = defaultValue
                    self.methodParamFields.append(textField)
                }
            }
        } else {
            // 파라미터 스펙이 없는 경우 JSON 예제 표시
            let jsonExample = EVMMethodHelper.defaultJsonExample(for: method)
            
            alert.addTextField { textField in
                textField.placeholder = "JSON Array Input (ex: [ {...} ])"
                textField.text = jsonExample
                self.methodParamFields.append(textField)
            }
        }
        
        // 실행 버튼 추가
        let executeAction = UIAlertAction(title: "Execute", style: .default) { [weak self] _ in
            self?.executeSelectedMethod()
        }
        
        // 취소 버튼
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(executeAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // 선택된 메소드 실행 (새로 추가된 메소드)
    private func executeSelectedMethod() {
        guard let method = selectedMethod, let provider = self.provider else {
            updateStatus("No method selected or provider is nil")
            return
        }
        
        var params: [Any]?
        
        if let methodParams = ethMethodParamSpecs[method] {
            // 구조화된 파라미터의 경우
            var paramDict: [String: Any] = [:]
            
            for (index, (key, _)) in methodParams.enumerated() {
                if index < methodParamFields.count {
                    let value = methodParamFields[index].text ?? ""
                    paramDict[key] = value
                }
            }
            
            // 빈 값은 제거
            let filteredParams = paramDict.filter { !($0.value as? String == "") }
            params = [filteredParams]
        } else {
            // JSON 형식 파라미터의 경우
            if let jsonString = methodParamFields.first?.text {
                params = EVMMethodHelper.parseJsonToParams(jsonString)
            }
        }
        
        guard let finalParams = params else {
            updateStatus("Invalid parameters")
            return
        }
        
        // 메소드 실행
        Task {
            do {
                let result = try await provider.request(method: method, params: finalParams)
                DispatchQueue.main.async {
                    self.updateStatus("Result: \(result ?? "nil")")
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            print(message)
        }
    }
}
