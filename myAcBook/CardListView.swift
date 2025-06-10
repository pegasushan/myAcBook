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
    @AppStorage("customLightBGColor") private var customLightBGColorHex: String = "#FEEAF2"
    @AppStorage("customDarkBGColor") private var customDarkBGColorHex: String = "#181A20"
    @AppStorage("customLightCardColor") private var customLightCardColorHex: String = "#FFFFFF"
    @AppStorage("customDarkCardColor") private var customDarkCardColorHex: String = "#23272F"
    @AppStorage("customLightSectionColor") private var customLightSectionColorHex: String = "#F6F7FA"
    @AppStorage("customDarkSectionColor") private var customDarkSectionColorHex: String = "#23272F"
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var cardViewModel = CardViewModel(context: PersistenceController.shared.container.viewContext)

    @State private var isAdding = false
    @State private var editingCard: Card?
    @State private var newName: String = ""
    @State private var showEmptyNameAlert = false
    @State private var showDuplicateAlert = false

    var customBGColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightBGColorHex)) : Color(UIColor(hex: customDarkBGColorHex))
    }
    var customCardColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightCardColorHex)) : Color(UIColor(hex: customDarkCardColorHex))
    }
    var customSectionColor: Color {
        colorScheme == .light ? Color(UIColor(hex: customLightSectionColorHex)) : Color(UIColor(hex: customDarkSectionColorHex))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                customBGColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 상단 카드 아이콘과 타이틀 복구
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.primary)
                            .padding(.top, 24)
                        Text(NSLocalizedString("card_management", comment: "카드 관리"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    // 카드 개수 안내
                    if cardViewModel.cards.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.gray.opacity(0.4))
                            Text(NSLocalizedString("no_cards", comment: "카드가 없습니다."))
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 24)
                    } else {
                        Text(String(format: NSLocalizedString("registered_card_count", comment: "등록된 카드 %d개"), cardViewModel.cards.count))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                    }
                    // 카드 목록
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(cardViewModel.cards, id: \.self) { card in
                                HStack(spacing: 12) {
                                    Image(systemName: "creditcard")
                                        .foregroundColor(.primary)
                                    Text(card.name ?? "")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Button(action: {
                                        editingCard = card
                                        newName = card.name ?? ""
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                    Button(action: {
                                        cardViewModel.deleteCard(card: card)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(customCardColor).shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 2))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    // 새 카드 추가
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("add_new_card_header", comment: "새 카드 추가"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.top, 18)
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
                                    let added = cardViewModel.addCard(name: trimmed)
                                    if added {
                                        newName = ""
                                    } else {
                                        showDuplicateAlert = true
                                    }
                                } else {
                                    showEmptyNameAlert = true
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(customCardColor).shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 2))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    Spacer()
                    // 하단 안내문구
                    Text(NSLocalizedString("card_usage_hint", comment: "등록한 카드는 내역 추가/수정에서 선택할 수 있습니다."))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
            }
            .alert("이미 같은 이름의 카드가 있습니다.", isPresented: $showDuplicateAlert) {
                Button("확인", role: .cancel) { }
            }
            .alert(NSLocalizedString("empty_card_name_alert", comment: "카드 이름을 입력해주세요."), isPresented: $showEmptyNameAlert) {
                Button(NSLocalizedString("confirm", comment: "확인"), role: .cancel) { }
            }
        }
    }
}
