import SwiftUI

struct AccountingTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("colorScheme") private var colorScheme: String = "system"

    @Binding var selectedRecord: Record?
    @Binding var isAddingNewRecord: Bool
    @Binding var isDeleteMode: Bool
    @Binding var selectedRecords: Set<Record>
    let filterSummaryView: AnyView
    let recordListSection: AnyView

    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundSolidColor").ignoresSafeArea()
                List {
                    filterSummaryView
                    recordListSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowBackground(Color("BackgroundSolidColor"))
                .background(Color("BackgroundSolidColor"))
            }
            .background(Color("BackgroundSolidColor"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isDeleteMode.toggle()
                        selectedRecords.removeAll()
                    }) {
                        Image(systemName: isDeleteMode ? "xmark" : "minus")
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("app_title", comment: "앱 타이틀"))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isDeleteMode {
                        if selectedRecords.isEmpty {
                            Text("선택")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(Color("HighlightColor"))
                        } else {
                            Button(action: {
                                withAnimation {
                                    for record in selectedRecords {
                                        viewContext.delete(record)
                                    }
                                    selectedRecords.removeAll()
                                    try? viewContext.save()
                                }
                            }) {
                                Text("선택 삭제 (\(selectedRecords.count))")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(Color("ExpenseColor"))
                            }
                        }
                    } else {
                        Button(action: {
                            isAddingNewRecord = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }
}
