import Foundation

enum OutfitStyle: String, CaseIterable {
    case korean = "korean"
    case japanese = "japanese"
    case business = "business"
    case sweetCool = "sweet_cool"
    case vintage = "vintage"
    case minimalist = "minimalist"
    case sporty = "sporty"

    var displayName: String {
        switch self {
        case .korean: return "韩系"
        case .japanese: return "日系"
        case .business: return "通勤"
        case .sweetCool: return "甜酷"
        case .vintage: return "复古"
        case .minimalist: return "极简"
        case .sporty: return "运动"
        }
    }

    var icon: String {
        switch self {
        case .korean: return "👔"
        case .japanese: return "👘"
        case .business: return "💼"
        case .sweetCool: return "🖤"
        case .vintage: return "🎞️"
        case .minimalist: return "⚪"
        case .sporty: return "🏃"
        }
    }
}

class OutfitGenerationService {

    static let shared = OutfitGenerationService()

    private init() {}

    func generateOutfit(clothes: [ClothItem], style: OutfitStyle?, weather: WeatherItem?, occasion: String?) -> OutfitItem {
        var filteredClothes = clothes

        if let weather = weather {
            let recommendations = WeatherService.shared.getClothingRecommendation(weather: weather)
            filteredClothes = clothes.filter { cloth in
                recommendations.contains(cloth.subType) || recommendations.contains(cloth.type.rawValue)
            }
        }

        if filteredClothes.isEmpty {
            filteredClothes = clothes
        }

        var topClothes = filteredClothes.filter { $0.type == "top" || $0.subType == "tshirt" || $0.subType == "shirt" || $0.subType == "polo" }
        var bottomClothes = filteredClothes.filter { $0.type == "bottom" || $0.subType == "jeans" || $0.subType == "pants" || $0.subType == "shorts" }
        var shoesClothes = filteredClothes.filter { $0.type == "shoes" || $0.subType == "sneakers" || $0.subType == "boots" }

        if topClothes.isEmpty { topClothes = clothes.filter { $0.type == "top" } }
        if bottomClothes.isEmpty { bottomClothes = clothes.filter { $0.type == "bottom" } }
        if shoesClothes.isEmpty { shoesClothes = clothes.filter { $0.type == "shoes" } }

        var selectedClothes: [ClothItem] = []

        if let top = topClothes.randomElement() {
            selectedClothes.append(top)
        }
        if let bottom = bottomClothes.randomElement() {
            selectedClothes.append(bottom)
        }
        if let shoes = shoesClothes.randomElement() {
            selectedClothes.append(shoes)
        }

        let outfitName: String
        if let style = style {
            outfitName = "\(style.displayName)穿搭"
        } else {
            outfitName = "智能穿搭方案"
        }

        return OutfitItem(
            id: UUID().uuidString,
            name: outfitName,
            style: style?.rawValue ?? "casual",
            clothes: selectedClothes
        )
    }

    func calculateStyleScore(outfit: [ClothItem], targetStyle: OutfitStyle) -> Double {
        var score = 0.0

        for cloth in outfit {
            switch cloth.type {
            case "top":
                if targetStyle == .business || targetStyle == .minimalist { score += 0.3 }
            case "bottom":
                if targetStyle == .korean || targetStyle == .japanese { score += 0.3 }
            case "shoes":
                if targetStyle == .sporty { score += 0.3 }
            default:
                break
            }
        }

        let topCount = outfit.filter { $0.type == "top" }.count
        let bottomCount = outfit.filter { $0.type == "bottom" }.count

        if topCount > 0 && bottomCount > 0 {
            score += 0.4
        }

        return min(score, 1.0)
    }
}