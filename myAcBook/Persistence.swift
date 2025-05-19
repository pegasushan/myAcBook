import CoreData

/// 옵션: 앱 실행 시 모든 기존 데이터를 삭제할지 여부
let shouldClearAllData = false

/// 옵션: 샘플 데이터를 삽입할지 여부
let shouldGenerateSampleData = false

struct PersistenceController {
    static let shared = PersistenceController(generateSampleData: shouldGenerateSampleData, clearAllData: shouldClearAllData)

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 여기서 샘플 데이터를 넣어준다
        for i in 0..<100 {
            let newRecord = Record(context: viewContext)
            newRecord.id = UUID()
            let isIncome = i % 3 == 0
            newRecord.type = isIncome ? NSLocalizedString("income", comment: "수입") : NSLocalizedString("expense", comment: "지출")
            newRecord.category = isIncome ?
                NSLocalizedString("salary", comment: "급여") :
                [
                    NSLocalizedString("food", comment: ""),
                    NSLocalizedString("transportation", comment: ""),
                    NSLocalizedString("shopping", comment: ""),
                    NSLocalizedString("leisure", comment: ""),
                    NSLocalizedString("etc", comment: "")
                ].randomElement()!
            newRecord.detail = String(format: NSLocalizedString("sample_detail", comment: "샘플 항목 상세"), isIncome ? NSLocalizedString("income", comment: "") : NSLocalizedString("expense", comment: ""), i + 1)
            newRecord.amount = floor(Double(Int.random(in: 1000...100000)))
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

    /// - clearAllData: If true, deletes all existing data in the persistent store during initialization.
    init(inMemory: Bool = false, generateSampleData: Bool = false, clearAllData: Bool = false) {
        container = NSPersistentContainer(name: "myAcBook")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError(String(format: NSLocalizedString("persistence_error", comment: "Core Data unresolved error"), "\(error)", "\(error.userInfo)"))
            }
        })

        // 옵션에 따라 기존 Core Data 데이터를 전부 삭제
        if clearAllData {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Record.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try container.viewContext.execute(deleteRequest)
                try container.viewContext.save()
                print("✅ 기존 데이터 삭제 완료")
            } catch {
                print("❌ 기존 데이터 삭제 실패: \(error)")
            }
        }

        // 샘플 데이터를 삽입하는 옵션
        if generateSampleData {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Record.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try container.viewContext.execute(deleteRequest)
            } catch {
                print("❌ 기존 데이터 삭제 실패: \(error)")
            }

            let viewContext = container.viewContext
            for i in 0..<100 {
                let newRecord = Record(context: viewContext)
                newRecord.id = UUID()
                let isIncome = i % 3 == 0
                newRecord.type = isIncome ? NSLocalizedString("income", comment: "수입") : NSLocalizedString("expense", comment: "지출")
                newRecord.category = isIncome ?
                    NSLocalizedString("salary", comment: "급여") :
                    [
                        NSLocalizedString("food", comment: ""),
                        NSLocalizedString("transportation", comment: ""),
                        NSLocalizedString("shopping", comment: ""),
                        NSLocalizedString("leisure", comment: ""),
                        NSLocalizedString("etc", comment: "")
                    ].randomElement()!
                newRecord.detail = String(format: NSLocalizedString("sample_detail", comment: "샘플 항목 상세"), isIncome ? NSLocalizedString("income", comment: "") : NSLocalizedString("expense", comment: ""), i + 1)
                newRecord.amount = floor(Double(Int.random(in: 1000...100000)))
                newRecord.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError(String(format: NSLocalizedString("persistence_error", comment: "Core Data unresolved error"), "\(nsError)", "\(nsError.userInfo)"))
            }
        }
    }
}
