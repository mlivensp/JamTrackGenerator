import SwiftData
import SwiftUI

struct StylesView: View {
    @Query(sort: \SchemaV1.Style.name) private var styles: [SchemaV1.Style]
    @Binding var selectedStyle: SchemaV1.Style?
    @Binding var navPath: NavigationPath
    
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
                            selectedStyle = style
                        }
                }
#else
                Text(style.name)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStyle = style
                    }
#endif
            }
        }
        .navigationTitle("Styles")
    }
}
