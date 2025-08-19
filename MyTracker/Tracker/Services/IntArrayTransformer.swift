import Foundation

@objc(IntArrayTransformer)
final class IntArrayTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, NSNumber.self]
    }
}
