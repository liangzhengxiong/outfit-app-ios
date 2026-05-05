import Foundation
import Alamofire

enum WTWAPI {
    static let baseURL = "http://localhost:3000"

    enum Auth {
        static func sendCode(phone: String) async throws {
            let _: EmptyResponse = try await AF.request(
                "\(WTWAPI.baseURL)/api/auth/send-code",
                method: .post,
                parameters: ["phone": phone]
            ).serializingDecodable().value
        }

        static func login(phone: String, code: String) async throws -> AuthResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/auth/login",
                method: .post,
                parameters: ["phone": phone, "code": code]
            ).serializingDecodable().value
        }

        static func wechatLogin(code: String) async throws -> AuthResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/auth/wechat",
                method: .post,
                parameters: ["code": code]
            ).serializingDecodable().value
        }
    }

    enum User {
        static func getMe() async throws -> UserResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/users/me"
            ).serializingDecodable().value
        }

        static func updateMe(_ params: [String: Any]) async throws -> UserResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/users/me",
                method: .put,
                parameters: params
            ).serializingDecodable().value
        }

        static func createBodyModel(_ params: [String: Any]) async throws -> BodyModelResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/users/body-model",
                method: .post,
                parameters: params
            ).serializingDecodable().value
        }
    }

    enum Clothes {
        static func list(type: String? = nil) async throws -> ClothesResponse {
            var params: [String: String] = [:]
            if let type = type {
                params["type"] = type
            }
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/clothes",
                parameters: params
            ).serializingDecodable().value
        }

        static func create(_ params: [String: Any]) async throws -> ClothResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/clothes",
                method: .post,
                parameters: params
            ).serializingDecodable().value
        }

        static func removeBackground(imageUrl: String) async throws -> RemoveBgResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/clothes/remove-bg",
                method: .post,
                parameters: ["imageUrl": imageUrl]
            ).serializingDecodable().value
        }
    }

    enum Outfits {
        static func generate(style: String?, weather: String?, occasion: String?) async throws -> GenerateOutfitResponse {
            var params: [String: String] = [:]
            if let style = style { params["style"] = style }
            if let weather = weather { params["weather"] = weather }
            if let occasion = occasion { params["occasion"] = occasion }
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/outfits/generate",
                method: .post,
                parameters: params
            ).serializingDecodable().value
        }

        static func create(name: String, style: String, clothIds: [String], weather: String? = nil, occasion: String? = nil) async throws -> GenerateOutfitResponse {
            var params: [String: Any] = ["name": name, "style": style, "clothIds": clothIds]
            if let weather = weather { params["weather"] = weather }
            if let occasion = occasion { params["occasion"] = occasion }
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/outfits",
                method: .post,
                parameters: params
            ).serializingDecodable().value
        }

        static func addToCalendar(date: String, outfitId: String?, note: String? = nil) async throws -> CalendarResponse {
            var params: [String: Any] = ["date": date]
            if let outfitId = outfitId { params["outfitId"] = outfitId }
            if let note = note { params["note"] = note }
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/outfits/calendar",
                method: .post,
                parameters: params
            ).serializingDecodable().value
        }

        static func calendar(startDate: String, endDate: String) async throws -> CalendarResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/outfits/calendar",
                parameters: ["startDate": startDate, "endDate": endDate]
            ).serializingDecodable().value
        }
    }

    enum AI {
        static func removeBackground(imageUrl: String) async throws -> RemoveBgResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/ai/remove-bg",
                method: .post,
                parameters: ["imageUrl": imageUrl]
            ).serializingDecodable().value
        }

        static func classifyBody(height: Int, weight: Int) async throws -> BodyTypeResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/ai/classify-body",
                method: .post,
                parameters: ["height": height, "weight": weight]
            ).serializingDecodable().value
        }

        static func getWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
            return try await AF.request(
                "\(WTWAPI.baseURL)/api/ai/weather",
                parameters: ["lat": lat, "lon": lon]
            ).serializingDecodable().value
        }
    }
}

struct EmptyResponse: Codable {}
struct AuthResponse: Codable { let token: String; let user: UserInfo }
struct UserInfo: Codable { let id: String; let phone: String?; let nickname: String? }
struct UserResponse: Codable { let id: String; let phone: String; let nickname: String; let avatar: String; let height: Int?; let weight: Int?; let bodyType: String? }
struct BodyModelResponse: Codable { let modelId: String; let matchedModels: [String] }
struct ClothesResponse: Codable { let clothes: [ClothItem]; let total: Int }
struct ClothItem: Codable { let id: String; let type: String; let subType: String; let size: String; let imageUrl: String; let removedBgUrl: String? }
struct ClothResponse: Codable { let cloth: ClothItem }
struct RemoveBgResponse: Codable { let resultUrl: String; let segments: [String] }
struct GenerateOutfitResponse: Codable { let outfit: OutfitItem }
struct OutfitItem: Codable { let id: String; let name: String; let style: String; let weather: String?; let occasion: String?; let clothes: [ClothItem] }
struct CalendarResponse: Codable { let records: [CalendarRecordItem]; let total: Int }
struct CalendarRecordItem: Codable { let id: String; let date: String; let outfit: OutfitItem? }
struct BodyTypeResponse: Codable { let bodyType: String; let confidence: Double; let bmi: Double? }
struct WeatherResponse: Codable { let weather: WeatherItem }
struct WeatherItem: Codable { let temp: Int; let condition: String; let humidity: Int; let wind: Int; let recommendations: [String]? }