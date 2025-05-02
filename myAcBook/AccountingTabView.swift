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
                Color.clear

                List {
                    filterSummaryView
                    recordListSection
                }
                .listStyle(.insetGrouped)
                .listRowBackground(Color.clear)
                .background(Color.clear)
            }
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
                    Text("AccountBook")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isDeleteMode {
                        if selectedRecords.isEmpty {
                            Text("선택")
                                .foregroundColor(.secondary)
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
                                    .foregroundColor(.red)
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
