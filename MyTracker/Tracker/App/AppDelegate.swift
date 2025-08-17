import UIKit
import CoreData

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let transformerName = NSValueTransformerName("IntArrayTransformer")
        ValueTransformer.setValueTransformer(IntArrayTransformer(), forName: transformerName)

        guard let modelURL = Bundle.main.url(forResource: "ModelCoreData", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model 'ModelCoreData'.")
        }

        if let entity = model.entitiesByName["TrackerCoreData"],
           let scheduleAttribute = entity.attributesByName["schedule"] {
            scheduleAttribute.valueTransformerName = transformerName.rawValue
            scheduleAttribute.attributeValueClassName = NSStringFromClass(NSArray.self)
        }

        let container = NSPersistentContainer(name: "ModelCoreData", managedObjectModel: model)
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
    
}

