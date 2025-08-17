import Foundation

extension Date {
    func formattedString(_ format: String = "dd.MM.yy", locale: Locale = Locale(identifier: "ru_RU")) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = locale
        return formatter.string(from: self)
    }
}
