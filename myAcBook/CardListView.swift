//
//  CardListView.swift
//  myAcBook
//
//  Created by 한상욱 on 5/21/25.
//

import SwiftUI

struct CardListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cardViewModel = CardViewModel(context: PersistenceController.shared.container.viewContext)

    @State private var isAdding = false
    @State private var editingCard: Card?
    @State private var newName: String = ""
    @State private var showEmptyNameAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section(header:
                        Text(NSLocalizedString("card_list_header", comment: "카드 목록"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                    ) {
                        if cardViewModel.cards.isEmpty {
                            Text(NSLocalizedString("no_cards", comment: "카드가 없습니다."))
                                .foregroundColor(.gray)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                        }
                        ForEach(cardViewModel.cards, id: \.self) { card in
                            Text(card.name ?? "")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        cardViewModel.deleteCard(card: card)
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                    Button {
                                        editingCard = card
                                        newName = card.name ?? ""
                                    } label: {
                                        Label("수정", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    Section(header:
                        Text(NSLocalizedString("add_new_card_header", comment: "새 카드 추가"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                    ) {
                        HStack(spacing: 12) {
                            TextField(NSLocalizedString("card_name_placeholder", comment: "카드 이름"), text: $newName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                            Button(NSLocalizedString("add", comment: "추가")) {
                                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty {
                                    cardViewModel.addCard(name: trimmed)
                                    newName = ""
                                } else {
                                    showEmptyNameAlert = true
                                }
                            }
                            .alert(NSLocalizedString("empty_card_name_alert", comment: "카드 이름을 입력해주세요."), isPresented: $showEmptyNameAlert) {
                                Button(NSLocalizedString("confirm", comment: "확인"), role: .cancel) { }
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("card_management", comment: "카드 관리"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text(NSLocalizedString("close", comment: "닫기"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                }
            }
        }
    }
}
