import UIKit
import CoreData

#if canImport(AppMetricaCore)
import AppMetricaCore
#endif

#if canImport(YandexMobileMetrica)
import YandexMobileMetrica
#endif

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let transformerName = NSValueTransformerName("IntArrayTransformer")
        ValueTransformer.setValueTransformer(IntArrayTransformer(), forName: transformerName)

        guard
            let modelURL = Bundle.main.url(forResource: "ModelCoreData", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Failed to load Core Data model 'ModelCoreData'.")
        }

        if let entity = model.entitiesByName["TrackerCoreData"],
           let scheduleAttribute = entity.attributesByName["schedule"] {
            scheduleAttribute.valueTransformerName = transformerName.rawValue
            scheduleAttribute.attributeValueClassName = NSStringFromClass(NSArray.self)
        }

        let container = NSPersistentContainer(name: "ModelCoreData", managedObjectModel: model)

        if let desc = container.persistentStoreDescriptions.first {
            desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        let ctx = container.viewContext
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true

        return container
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let rel = persistentContainer
            .managedObjectModel
            .entitiesByName["TrackerCategoryCoreData"]?
            .relationshipsByName["trackers"]

        if let rel = rel {
            print("trackers isToMany =", rel.isToMany)
        }
        let appMetricaApiKey = "81efead2-f8f7-4610-bd05-1203ae77ac36"

        #if canImport(AppMetricaCore)
        if let config = AppMetricaConfiguration(apiKey: appMetricaApiKey) {
            AppMetrica.activate(with: config)
            print("[AppMetrica] Activated via SPM (AppMetricaCore).")
        } else {
            print("[AppMetrica] Failed to create AppMetricaConfiguration — check API key.")
        }
        #elseif canImport(YandexMobileMetrica)
        if let config = YMMYandexMetricaConfiguration(apiKey: appMetricaApiKey) {
            YMMYandexMetrica.activate(with: config)
            YMMYandexMetrica.enableLogging(true)
            print("[AppMetrica] Activated via CocoaPods (YandexMobileMetrica).")
        } else {
            print("[AppMetrica] Failed to create YMMYandexMetricaConfiguration — check API key.")
        }
        #else
        print("[AppMetrica] SDK not found. Make sure the package (SPM) or pod is added to the app target.")
        #endif

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
