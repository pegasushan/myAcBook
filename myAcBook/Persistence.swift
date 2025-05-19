import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 여기서 샘플 데이터를 넣어준다
        for i in 0..<10 {
            let newRecord = Record(context: viewContext)
            newRecord.id = UUID()
            newRecord.category = [
                NSLocalizedString("food", comment: ""),
                NSLocalizedString("transportation", comment: ""),
                NSLocalizedString("shopping", comment: ""),
                NSLocalizedString("leisure", comment: ""),
                NSLocalizedString("etc", comment: "")
            ].randomElement()!
            newRecord.detail = String(format: NSLocalizedString("sample_detail", comment: "샘플 항목 상세"), i + 1)
            newRecord.amount = Double(Int.random(in: 1000...100000))
            newRecord.amount = floor(newRecord.amount)
            newRecord.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError(String(format: NSLocalizedString("persistence_error", comment: "Core Data unresolved error"), "\(nsError)", "\(nsError.userInfo)"))
        }
        
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "myAcBook")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError(String(format: NSLocalizedString("persistence_error", comment: "Core Data unresolved error"), "\(error)", "\(error.userInfo)"))
            }
        })
    }
}
