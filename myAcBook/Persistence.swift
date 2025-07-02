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
                fatalError("Unresolved error \(error), \(error.userInfo)")
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
                ("food", "expense"),
                ("transportation", "expense"),
                ("shopping", "expense"),
                ("leisure", "expense"),
                ("etc", "expense"),
                ("salary", "income"),
                ("side_income", "income")
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

            for i in 0..<2 {
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

        // 앱 최초 실행 시 기본 카테고리 자동 입력 (최초 1회만)
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "didInsertDefaultCategories") {
            let defaultCategories: [(String, String)] = [
                ("salary", "income"),
                ("side_income", "income"),
                ("food", "expense"),
                ("beverage", "expense"),
                ("shopping", "expense")
            ]
            let categoryFetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
            let existingCategories = (try? container.viewContext.fetch(categoryFetch)) ?? []
            for (name, type) in defaultCategories {
                let exists = existingCategories.contains { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == name && ($0.type ?? "") == type }
                if !exists {
                    let category = AppCategory(context: container.viewContext)
                    category.id = UUID()
                    category.name = name
                    category.type = type
                }
            }
            do {
                try container.viewContext.save()
                defaults.set(true, forKey: "didInsertDefaultCategories")
            } catch {
                print("❌ 기본 카테고리 저장 실패: \(error)")
            }
        }
        // 앱 최초 실행 시 기본 카드 자동 입력 (최초 1회만)
        if !defaults.bool(forKey: "didInsertDefaultCards") {
            let defaultCards: [String] = ["shinhan_card", "samsung_card"]
            let cardFetch: NSFetchRequest<Card> = Card.fetchRequest()
            let existingCards = (try? container.viewContext.fetch(cardFetch)) ?? []
            for name in defaultCards {
                let exists = existingCards.contains { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == name }
                if !exists {
                    let card = Card(context: container.viewContext)
                    card.id = UUID()
                    card.name = name
                    card.createdAt = Date()
                }
            }
            do {
                try container.viewContext.save()
                defaults.set(true, forKey: "didInsertDefaultCards")
            } catch {
                print("❌ 기본 카드 저장 실패: \(error)")
            }
        }
        // === 카드 한글 → 영문 키 마이그레이션 ===
        let cardMigrationMap: [String: String] = [
            "삼성카드": "samsung_card",
            "신한카드": "shinhan_card",
            "현대카드": "hyundai_card",
            "국민카드": "kookmin_card"
        ]
        let cardFetch: NSFetchRequest<Card> = Card.fetchRequest()
        if let cards = try? container.viewContext.fetch(cardFetch) {
            for card in cards {
                if let oldName = card.name, let newName = cardMigrationMap[oldName] {
                    card.name = newName
                }
            }
            try? container.viewContext.save()
        }

        // === 카테고리 한글 → 영문 키 마이그레이션 ===
        let migrationMap: [String: String] = [
            "쇼핑": "shopping",
            "식대": "food",
            "음료": "beverage",
            "급여": "salary",
            "부수입": "side_income",
            "교통비": "transportation",
            "여가": "leisure",
            "기타": "etc"
        ]
        let categoryFetch: NSFetchRequest<AppCategory> = AppCategory.fetchRequest()
        if let categories = try? container.viewContext.fetch(categoryFetch) {
            for category in categories {
                if let oldName = category.name, let newName = migrationMap[oldName] {
                    category.name = newName
                }
            }
            try? container.viewContext.save()
        }
    }
}
