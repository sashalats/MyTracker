import CoreData

final class TrackerCategoryStore {
    private let context: NSManagedObjectContext

    var onCategoriesChanged: (([TrackerCategoryCoreData]) -> Void)?

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Helpers
    /// Единая нормализация ключа категории: убираем пробелы по краям.
    /// (При необходимости сюда можно добавить .lowercased())
    private func normalized(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Fetch
    func fetchAllCategories() -> [TrackerCategoryCoreData] {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    /// Поиск категории по названию (без учета регистра, с нормализацией)
    func fetchCategory(with title: String) -> TrackerCategoryCoreData? {
        let key = normalized(title)
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        // =[c] — сравнение без учета регистра
        request.predicate = NSPredicate(format: "title =[c] %@", key)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    // MARK: - Create
    func createCategoryIfNeeded(title: String) -> TrackerCategoryCoreData {
        let key = normalized(title)
        if let existing = fetchCategory(with: key) {
            return existing
        }
        return createNewCategory(title: key)
    }

    func createNewCategory(title: String) -> TrackerCategoryCoreData {
        let key = normalized(title)
        let category = TrackerCategoryCoreData(context: context)
        category.title = key
        saveContext()
        notifyObservers()
        return category
    }

    // MARK: - Update/Delete
    func renameCategory(_ category: TrackerCategoryCoreData, to newTitle: String) {
        category.title = normalized(newTitle)
        saveContext()
        notifyObservers()
    }

    func deleteCategory(_ category: TrackerCategoryCoreData) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)

        do {
            let trackers = try context.fetch(request)
            trackers.forEach { context.delete($0) }
        } catch {
            print("Ошибка при получении трекеров для удаления категории: \(error)")
        }

        context.delete(category)
        saveContext()
        notifyObservers()
    }

    // MARK: - Private
    private func notifyObservers() {
        onCategoriesChanged?(fetchAllCategories())
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения контекста категории: \(error)")
        }
    }
}
