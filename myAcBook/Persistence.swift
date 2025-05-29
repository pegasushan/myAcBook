import CoreData

/// 옵션: 앱 실행 시 모든 기존 데이터를 삭제할지 여부
let shouldClearAllData = true

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
            if !isIncome {
                let cardName = ["삼성카드", "현대카드", "국민카드", "신한카드"].randomElement()!
                let cardFetch: NSFetchRequest<Card> = Card.fetchRequest()
                cardFetch.predicate = NSPredicate(format: "name == %@", cardName)
                if let existingCard = try? viewContext.fetch(cardFetch).first {
                    newRecord.card = existingCard
                    _ = newRecord.card?.name  // Force Core Data to load the relationship
                } else {
                    let newCard = Card(context: viewContext)
                    newCard.id = UUID()
                    newCard.name = cardName
                    newRecord.card = newCard
                    _ = newRecord.card?.name  // Force Core Data to load the relationship
                }
                newRecord.paymentType = NSLocalizedString("card", comment: "카드")
            } else {
                newRecord.paymentType = NSLocalizedString("cash", comment: "현금")
            }
            let categoryNames = isIncome
                ? ["salary", "side_income"]
                : ["food", "transportation", "shopping", "leisure", "etc"]
            let selectedKey = categoryNames.randomElement()!
            let categoryName = selectedKey
            let categoryFetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
            categoryFetch.predicate = NSPredicate(format: "name == %@", categoryName)
            if let matchedCategory = try? viewContext.fetch(categoryFetch).first {
                newRecord.categoryRelation = matchedCategory
            }
            let typeKey = isIncome ? "income" : "expense"
            newRecord.detail = String(format: NSLocalizedString("sample_detail", comment: "샘플 항목 상세"), NSLocalizedString(typeKey, comment: ""), i + 1)
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
            let categoryFetchRequest: NSFetchRequest<NSFetchRequestResult> = AppCategory.fetchRequest()
            let categoryDeleteRequest = NSBatchDeleteRequest(fetchRequest: categoryFetchRequest)
            do {
                try container.viewContext.execute(categoryDeleteRequest)
                try container.viewContext.save()
                print("✅ 기존 카테고리 삭제 완료")
            } catch {
                print("❌ 기존 카테고리 삭제 실패: \(error)")
            }
        }

        // 샘플 데이터를 삽입하는 옵션
        if generateSampleData {
            let viewContext = container.viewContext
            let deleteRequests: [NSFetchRequest<NSFetchRequestResult>] = [
                Record.fetchRequest(),
                Card.fetchRequest()
            ]
            for request in deleteRequests {
                let delete = NSBatchDeleteRequest(fetchRequest: request)
                do {
                    try container.viewContext.execute(delete)
                } catch {
                    print("❌ 기존 데이터 삭제 실패: \(error)")
                }
            }

            let sampleCategories: [(String, String)] = [
                ("식비", "expense"),
                ("교통비", "expense"),
                ("쇼핑", "expense"),
                ("여가", "expense"),
                ("기타", "expense"),
                ("월급", "income"),
                ("보너스", "income")
            ]

            for (name, type) in sampleCategories {
                let category = AppCategory(context: viewContext)
                category.id = UUID()
                category.name = name
                category.type = type
            }

            let categoryNames = [
                "food",
                "transportation",
                "shopping",
                "leisure",
                "etc",
                "salary",
                "side_income"
            ]

            var categoriesByName: [String: String] = [:]
            for name in categoryNames {
                categoriesByName[name] = name
            }

            let existingCards = try? viewContext.fetch(Card.fetchRequest())
            existingCards?.forEach {
                if $0.id == nil {
                    $0.id = UUID()
                    print("🛠 기존 카드에 UUID 할당: \($0.name ?? "no name")")
                }
            }

            for i in 0..<100 {
                let newRecord = Record(context: viewContext)
                newRecord.id = UUID()
                let isIncome = i % 3 == 0
                newRecord.type = isIncome ? NSLocalizedString("income", comment: "수입") : NSLocalizedString("expense", comment: "지출")
                if !isIncome {
                    let cardName = ["삼성카드", "현대카드", "국민카드", "신한카드"].randomElement()!
                    let cardFetch: NSFetchRequest<Card> = Card.fetchRequest()
                    cardFetch.predicate = NSPredicate(format: "name == %@", cardName)
                    if let existingCard = try? viewContext.fetch(cardFetch).first {
                        if existingCard.name == nil || existingCard.name != cardName {
                            existingCard.name = cardName
                        }
                        newRecord.card = existingCard
                        _ = newRecord.card?.name  // Force Core Data to load the relationship
                        let displayDate = newRecord.date ?? Date()
                        print("✅ \(displayDate) 기존 카드 연결됨: \(existingCard.name ?? "알 수 없음")")
                    } else {
                        let newCard = Card(context: viewContext)
                        newCard.id = UUID()
                        newCard.name = cardName
                        newRecord.card = newCard
                        _ = newRecord.card?.name  // Force Core Data to load the relationship
                        print("✅ \(newRecord.date ?? Date()) 새 카드 생성 및 연결됨: \(newCard.name ?? "알 수 없음")")
                    }
                    newRecord.paymentType = NSLocalizedString("card", comment: "카드")
                } else {
                    newRecord.paymentType = NSLocalizedString("cash", comment: "현금")
                }
                let categoryFetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
                categoryFetch.predicate = NSPredicate(format: "type == %@", isIncome ? "income" : "expense")
                let availableCategories = try? viewContext.fetch(categoryFetch)
                if let selectedCategory = availableCategories?.randomElement() {
                    newRecord.categoryRelation = selectedCategory
                } else {
                    print("❌ 사용할 수 있는 \(isIncome ? "수입" : "지출") 카테고리가 없음")
                }
                let typeKey = isIncome ? "income" : "expense"
                newRecord.detail = String(format: NSLocalizedString("sample_detail", comment: "샘플 항목 상세"), NSLocalizedString(typeKey, comment: ""), i + 1)
                newRecord.amount = floor(Double(Int.random(in: 1000...100000)))
                newRecord.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            }

            do {
                try viewContext.save()
                // 샘플 데이터 저장 완료
                print("📦 샘플 데이터 저장 완료 - 카드 수: \((try? viewContext.fetch(Card.fetchRequest()).count) ?? 0)")
            } catch {
                let nsError = error as NSError
                fatalError(String(format: NSLocalizedString("persistence_error", comment: "Core Data unresolved error"), "\(nsError)", "\(nsError.userInfo)"))
            }
        }
    }
}
