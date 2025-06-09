//
//  CardViewModel.swift
//  myAcBook
//
//  Created by 한상욱 on 5/21/25.
//

import Foundation
import CoreData

class CardViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var cards: [Card] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchCards()
    }

    // MARK: - Fetch
    func fetchCards() {
        let request: NSFetchRequest<Card> = Card.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Card.createdAt, ascending: true)]

        do {
            cards = try viewContext.fetch(request)
        } catch {
            print("❌ 카드 목록 불러오기 실패: \(error)")
        }
    }

    // MARK: - Add
    /// 중복이면 false, 추가 성공 시 true 반환
    func addCard(name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isDuplicate = cards.contains { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed }
        if isDuplicate || trimmed.isEmpty {
            return false
        }
        let newCard = Card(context: viewContext)
        newCard.id = UUID()
        newCard.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newCard.createdAt = Date()
        saveContext()
        return true
    }

    // MARK: - Update
    func updateCard(card: Card, newName: String) {
        card.name = newName
        saveContext()
    }

    // MARK: - Delete
    func deleteCard(card: Card) {
        viewContext.delete(card)
        saveContext()
    }

    // MARK: - Save
    private func saveContext() {
        do {
            try viewContext.save()
            fetchCards()  // 저장 후 목록 새로고침
        } catch {
            print("❌ 카드 저장 실패: \(error)")
        }
    }

    // MARK: - 중복 카드 삭제
    func removeDuplicateCards() {
        var seenNames = Set<String>()
        var cardsToDelete: [Card] = []
        for card in cards {
            let name = card.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if name.isEmpty { continue }
            if seenNames.contains(name) {
                cardsToDelete.append(card)
            } else {
                seenNames.insert(name)
            }
        }
        for card in cardsToDelete {
            viewContext.delete(card)
        }
        if !cardsToDelete.isEmpty {
            saveContext()
            print("🗑️ 중복 카드 자동 삭제: \(cardsToDelete.map { $0.name ?? "-" })")
        }
    }
}
