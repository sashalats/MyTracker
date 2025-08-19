import CoreData
import UIKit

final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    
    var onChange: (([TrackerCategory]) -> Void)?
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func startObserving() {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isPinned == NO"),
            NSPredicate(format: "category != NULL"),
            NSPredicate(format: "category.title != NULL"),
            NSPredicate(format: "category.title != ''")
        ])
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "category.title",
            cacheName: nil
        )
        frc.delegate = self
        fetchedResultsController = frc
        
        do {
            try frc.performFetch()
        } catch {
            print("TrackerStore FRC performFetch error: \(error)")
        }
        
        publishSnapshot()
    }
    
    private func publishSnapshot() {
        var sections: [TrackerCategory] = []
        
        let pinnedRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        pinnedRequest.predicate = NSPredicate(format: "isPinned == YES")
        pinnedRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let pinnedCore = (try? context.fetch(pinnedRequest)) ?? []
        let pinned = pinnedCore.compactMap(makeTracker)
        if !pinned.isEmpty {
            sections.append(TrackerCategory(title: "Закреплённые", trackers: pinned))
        }
        
        let objects = fetchedResultsController?.fetchedObjects ?? []
        let grouped = Dictionary(grouping: objects) { core -> String in
            (core.category?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let sortedKeys = grouped.keys
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCompare($1) == .orderedAscending }
        
        for key in sortedKeys {
            let trackers = (grouped[key] ?? []).compactMap(makeTracker)
            if !trackers.isEmpty {
                sections.append(TrackerCategory(title: key, trackers: trackers))
            }
        }
        
        onChange?(sections)
    }
    
    func fetchTrackersGroupedByCategory() -> [TrackerCategory] {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        let coreDataObjects = (try? context.fetch(request)) ?? []
        
        let pinnedTrackers = coreDataObjects
            .filter { $0.isPinned }
            .compactMap(makeTracker)
        
        var result: [TrackerCategory] = []
        if !pinnedTrackers.isEmpty {
            result.append(TrackerCategory(title: "Закреплённые", trackers: pinnedTrackers))
        }
        
        let grouped = Dictionary(grouping: coreDataObjects.filter {
            guard !$0.isPinned, let title = $0.category?.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return false }
            return true
        }) { ($0.category!.title!.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let sortedCategoryTitles = grouped.keys.sorted { $0.localizedCompare($1) == .orderedAscending }
        
        for title in sortedCategoryTitles {
            guard let trackersCore: [TrackerCoreData] = grouped[title] else { continue }
            let trackers = trackersCore.compactMap(makeTracker)
            
            if !trackers.isEmpty {
                result.append(TrackerCategory(title: title, trackers: trackers))
            }
        }
        return result
    }
    
    private func makeTracker(from core: TrackerCoreData) -> Tracker? {
        guard
            let id = core.id,
            let name = core.name,
            let emoji = core.emoji,
            let colorHex = core.color
        else { return nil }
        
        let schedule: [DayOfWeek]
        if let raw = core.schedule as? [Int] {
            schedule = raw.compactMap(DayOfWeek.init(rawValue:))
        } else {
            schedule = []
        }
        
        return Tracker(
            id: id,
            name: name,
            color: UIColor(hex: colorHex),
            emoji: emoji,
            schedule: schedule,
            isPinned: core.isPinned
        )
    }
    
    func addTracker(id: UUID, name: String, emoji: String, colorHex: String, schedule: [DayOfWeek], category: TrackerCategoryCoreData) {
        let tracker = TrackerCoreData(context: context)
        tracker.id = id
        tracker.name = name
        tracker.emoji = emoji
        tracker.color = colorHex
        tracker.schedule = schedule.map { $0.rawValue } as NSObject
        tracker.category = category
        tracker.isPinned = false
        saveContext()
    }
    
    func updatePinState(for id: UUID, isPinned: Bool) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let tracker = try context.fetch(request).first {
                tracker.isPinned = isPinned
                saveContext()
            }
        } catch {
            print("Ошибка при обновлении состояния pin для трекера \(id): \(error)")
        }
    }
    
    func deleteTracker(for id: UUID) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let tracker = try context.fetch(request).first {
                context.delete(tracker)
                saveContext()
            }
        } catch {
            print("Ошибка при удалении трекера \(id): \(error)")
        }
    }
    
    func updateTracker(_ tracker: Tracker, newCategory: TrackerCategoryCoreData?) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        do {
            if let existing = try context.fetch(request).first {
                existing.name = tracker.name
                existing.emoji = tracker.emoji
                existing.color = tracker.color.toHexString()
                existing.schedule = tracker.schedule.map { $0.rawValue } as NSObject
                existing.isPinned = tracker.isPinned
                
                if let newCategory = newCategory {
                    existing.category = newCategory
                }
                
                saveContext()
            }
        } catch {
            print("Ошибка при обновлении трекера \(tracker.id): \(error)")
        }
    }
    
    func trackerExists(withId id: UUID) -> Bool {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return (try? context.count(for: request)) ?? 0 > 0
    }
    
    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения контекста: \(error)")
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        publishSnapshot()
    }
}
