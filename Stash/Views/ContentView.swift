import SwiftUI
import AppKit
import Kingfisher

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    @State private var present = false
    @State private var sheetHeight: CGFloat = .zero
    @State private var anchorId: UUID?
    @State private var error: Error?
    
    private var welcome: Bool {
        cabinet.storedEntries.count <= 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toolbar(present: $present) {
                    do {
                        let name = cabinet.directoryDefaultName(anchorId: anchorId)
                        let directory = Group(id: UUID(), name: name)
                        try cabinet.relocate(entry: directory, anchorId: anchorId)
                        
                        let deadlineTime = DispatchTime.now() + 0.25
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                            NotificationCenter.default.post(name: .onDoubleTapRowView, object: directory)
                        }
                    } catch {
                        self.error = error
                        ErrorTracker.shared.add(error)
                    }
                }
                if welcome {
                    HStack(alignment: .top, spacing: 0) {
                        Text("Tap ")
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Image(systemName: "link.badge.plus")
                                Text(" to Create Bookmark")
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Image(systemName: "folder.badge.plus")
                                Text(" to Create Group")
                            }
                        }
                    }
                    .frame(height: 147)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                } else {
                    OutlineView(entries: $cabinet.storedEntries, anchorId: $anchorId, presentingModal: $present) {
                        self.anchorId = $0
                    }
                    ModifierKeyMonitorView(listen: !present)
                        .frame(width: 0, height: 0)
                }
            }
            .sheet(isPresented: $present, onDismiss: nil) {
                CraftModalView(anchorId: $anchorId)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .interactiveDismissDisabled(true)
                    .modifier(GetHeightModifier(height: $sheetHeight))
                    .presentationDetents([.height(sheetHeight)])
            }
        }
        .alert("Error", isPresented: Binding(
            get: { error != nil },
            set: { x in }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error?.localizedDescription ?? "")
        }
    }
}



struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color.clear
            }
        )
    }
}
