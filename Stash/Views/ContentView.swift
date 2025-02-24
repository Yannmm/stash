import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    @State private var present = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toolbar(present: $present)
                OutlineView(items: $cabinet.entries)
            }
            .sheet(isPresented: $present, onDismiss: nil) {
                ModalView()
                    .frame(width: 300, height: 200)
                    .interactiveDismissDisabled(true)
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}

// Example Modal View
struct ModalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Modal Content")
            Button("Close") {
                dismiss()
            }
        }
        .padding()
    }
}





