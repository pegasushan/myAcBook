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
            ZStack {
                Color("BackgroundSolidColor").ignoresSafeArea()
                VStack(spacing: 0) {
                    // 상단 타이틀
                    HStack(spacing: 10) {
                        // Image(systemName: "creditcard.fill") // 이모티콘 제거
                        // 상단 텍스트도 이미 제거됨
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    // 리스트와 타이틀 사이 여백
                    Spacer().frame(height: 8)
                    List {
                        Section(header:
                            Text(NSLocalizedString("card_list_header", comment: "카드 목록"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("HighlightColor"))
                                .padding(.bottom, 2)
                        ) {
                            if cardViewModel.cards.isEmpty {
                                Text(NSLocalizedString("no_cards", comment: "카드가 없습니다."))
                                    .foregroundColor(Color("HighlightColor"))
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                            }
                            ForEach(cardViewModel.cards, id: \.self) { card in
                                Text(card.name ?? "")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(Color("HighlightColor"))
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
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("HighlightColor"))
                                .padding(.bottom, 2)
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.gray)
                                TextField(NSLocalizedString("card_name_placeholder", comment: "카드 이름"), text: $newName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                Spacer()
                                Button(action: {
                                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                                    if !trimmed.isEmpty {
                                        cardViewModel.addCard(name: trimmed)
                                        newName = ""
                                    } else {
                                        showEmptyNameAlert = true
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.blue)
                                        .padding(6)
                                        .background(Color.white.opacity(0.7))
                                        .clipShape(Circle())
                                }
                                .alert(NSLocalizedString("empty_card_name_alert", comment: "카드 이름을 입력해주세요."), isPresented: $showEmptyNameAlert) {
                                    Button(NSLocalizedString("confirm", comment: "확인"), role: .cancel) { }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(Color("BackgroundSolidColor"))
                    .scrollContentBackground(.hidden)
                    .background(Color("BackgroundSolidColor"))
                    .onAppear {
                        UITableView.appearance().backgroundColor = UIColor.clear
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
