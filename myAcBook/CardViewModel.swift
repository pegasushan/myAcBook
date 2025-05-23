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
    func addCard(name: String) {
        let newCard = Card(context: viewContext)
        newCard.id = UUID()
        newCard.name = name
        newCard.createdAt = Date()

        saveContext()
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
}
