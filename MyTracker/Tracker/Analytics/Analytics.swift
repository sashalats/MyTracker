import Foundation

#if canImport(AppMetricaCore)
import AppMetricaCore
#endif

#if canImport(YandexMobileMetrica)
import YandexMobileMetrica
#endif

enum AnalyticsEventType: String {
    case open  = "open"
    case close = "close"
    case click = "click"
}

enum AnalyticsScreen: String {
    case main = "Main"
}

enum AnalyticsItem: String {
    case addTrack  = "add_track"
    case track     = "track"
    case filter    = "filter"
    case edit      = "edit"
    case delete    = "delete"
}

enum Analytics {
    static func setupAppMetrica(apiKey: String) {
        #if canImport(AppMetricaCore)
        if let config = AppMetricaConfiguration(apiKey: apiKey) {
            AppMetrica.activate(with: config)
        }
        #elseif canImport(YandexMobileMetrica)
        let config = YMMYandexMetricaConfiguration(apiKey: apiKey)
        YMMYandexMetrica.activate(with: config!)
        YMMYandexMetrica.enableLogging(true)
        #else
        print("[Analytics] AppMetrica SDK не найден — отправка будет только в логи.")
        #endif
    }

    static func send(event: AnalyticsEventType,
                     screen: AnalyticsScreen,
                     item: AnalyticsItem? = nil,
                     extra: [String: Any]? = nil) {

        var params: [String: Any] = [
            "event":  event.rawValue,
            "screen": screen.rawValue
        ]
        if let item { params["item"] = item.rawValue }
        if let extra { params.merge(extra) { $1 } }

        if let json = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted),
           let text = String(data: json, encoding: .utf8) {
            print("[Analytics] ui_event params:\n\(text)")
        } else {
            print("[Analytics] ui_event params: \(params)")
        }

        #if canImport(AppMetricaCore)
        AppMetrica.reportEvent(name: "ui_event", parameters: params)
        #elseif canImport(YandexMobileMetrica)
        YMMYandexMetrica.reportEvent("ui_event", parameters: params, onFailure: nil)
        #else
        // no-op
        #endif
    }
}
