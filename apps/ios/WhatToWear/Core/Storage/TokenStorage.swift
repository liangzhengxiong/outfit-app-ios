import Foundation

class TokenStorage {

    static let shared = TokenStorage()

    private let TOKEN_KEY = "authToken"
    private let USER_ID_KEY = "userId"
    private let USER_PHONE_KEY = "userPhone"

    private init() {}

    var token: String? {
        get {
            return UserDefaults.standard.string(forKey: TOKEN_KEY)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: TOKEN_KEY)
            } else {
                UserDefaults.standard.removeObject(forKey: TOKEN_KEY)
            }
        }
    }

    var userId: String? {
        get {
            return UserDefaults.standard.string(forKey: USER_ID_KEY)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: USER_ID_KEY)
            } else {
                UserDefaults.standard.removeObject(forKey: USER_ID_KEY)
            }
        }
    }

    var userPhone: String? {
        get {
            return UserDefaults.standard.string(forKey: USER_PHONE_KEY)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: USER_PHONE_KEY)
            } else {
                UserDefaults.standard.removeObject(forKey: USER_PHONE_KEY)
            }
        }
    }

    var isLoggedIn: Bool {
        return token != nil && !token!.isEmpty
    }

    func saveAuthData(token: String, userId: String, phone: String? = nil) {
        self.token = token
        self.userId = userId
        if let phone = phone {
            self.userPhone = phone
        }
    }

    func clearAuthData() {
        token = nil
        userId = nil
        userPhone = nil
    }
}

class AuthService {

    static let shared = AuthService()

    private init() {}

    func sendCode(phone: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                try await WTWAPI.Auth.sendCode(phone: phone)
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func login(phone: String, code: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        Task {
            do {
                let response = try await WTWAPI.Auth.login(phone: phone, code: code)
                TokenStorage.shared.saveAuthData(token: response.token, userId: response.user.id, phone: response.user.phone)
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func wechatLogin(code: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        Task {
            do {
                let response = try await WTWAPI.Auth.wechatLogin(code: code)
                TokenStorage.shared.saveAuthData(token: response.token, userId: response.user.id)
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func logout() {
        TokenStorage.shared.clearAuthData()
    }

    func getCurrentUser() -> UserInfo? {
        guard TokenStorage.shared.isLoggedIn else { return nil }
        return UserInfo(id: TokenStorage.shared.userId ?? "", phone: TokenStorage.shared.userPhone)
    }
}