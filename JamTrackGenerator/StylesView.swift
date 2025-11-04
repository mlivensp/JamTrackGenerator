import SwiftData
import SwiftUI

struct StylesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var navManager: NavigationStateManager
    
    @Query(sort: \SchemaV1.Style.name) private var styles: [SchemaV1.Style]
    @Binding var selectedStyleID: Style.ID?
    
    var body: some View {
        List {
            ForEach(styles) { style in
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    NavigationLink(value: style) {
                        Text(style.name)
                    }
                } else {
                    Text(style.name)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            proxyStyleID.wrappedValue = style.id
                        }
                }
#else
                Text(style.name)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        proxyStyleID.wrappedValue = style.id
                    }
#endif
            }
        }
        .navigationTitle("Styles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addStyle) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
    
    var proxyStyleID: Binding<Style.ID?> {
        Binding(
        get: { selectedStyleID },
        set: { newStyleID in
            navManager.requestNavigation {
                selectedStyleID = newStyleID
            }
        }
        )
    }

    private func addStyle() {
        // TODO: need to check for unsaved changes in current thang first
        withAnimation {
            navManager.requestNavigation {
                let style = Style(name: "New Style")
                modelContext.insert(style)
                
                do {
                    try modelContext.save()
                } catch {
                    fatalError(error.localizedDescription)
                }
                
                selectedStyleID = style.id
            }
        }
    }
}
