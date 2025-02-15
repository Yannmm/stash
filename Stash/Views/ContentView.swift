import SwiftUI
import AppKit

struct ContentView: View {
    
    @State private var data: [ListItem] = [
        ListItem(title: "Section 1", children: [
            ListItem(title: "Item 1.1"),
            ListItem(title: "Item 1.2"),
            ListItem(title: "Subsection 1.3", children: [
                ListItem(title: "Item 1.3.1"),
                ListItem(title: "Item 1.3.2")
            ])
        ]),
        ListItem(title: "Section 2", children: [
            ListItem(title: "Item 2.1"),
            ListItem(title: "Subsection 2.2", children: [
                ListItem(title: "Item 2.2.1")
            ])
        ])
    ]

    var body: some View {
        VStack {
            OutlineView(items: $data)
                .frame(minWidth: 300, minHeight: 400)
        }
    }
    
}



