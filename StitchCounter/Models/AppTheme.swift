import Foundation

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case seaCottage = "sea_cottage"
    case dustyRose = "dusty_rose"
    case goldenHearth = "golden_hearth"
    case forestFiber = "forest_fiber"
    case cloudSoft = "cloud_soft"
    case yarnCandy = "yarn_candy"

    var id: String { rawValue }

    var displayNameLocalizationKey: String {
        switch self {
        case .seaCottage: return "theme.displayName.seaCottage"
        case .dustyRose: return "theme.displayName.dustyRose"
        case .goldenHearth: return "theme.displayName.goldenHearth"
        case .forestFiber: return "theme.displayName.forestFiber"
        case .cloudSoft: return "theme.displayName.cloudSoft"
        case .yarnCandy: return "theme.displayName.yarnCandy"
        }
    }

    var alternateIconAssetName: String {
        switch self {
        case .seaCottage: return "AppIconSeaCottage"
        case .dustyRose: return "AppIconDustyRose"
        case .goldenHearth: return "AppIconGoldenHearth"
        case .forestFiber: return "AppIconForestFiber"
        case .cloudSoft: return "AppIconCloudSoft"
        case .yarnCandy: return "AppIconYarnCandy"
        }
    }
}
