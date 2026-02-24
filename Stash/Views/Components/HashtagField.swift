//
//  HashtagField.swift
//  Stash
//
//  Created by Rayman on 2026/2/24.
//

import SwiftUI

struct HashtagField: View {
//    @Binding var loading: Bool
//    @Binding var icon: Icon?
//    @Binding var path: String?
//    @FocusState.Binding var focusedField: EntryEditor.Field?
    
    @FocusState private var focused: Bool
    
    @State private var title: String?
    
    var body: some View {
        HashtagTextField(text: $title ?? "", focused: focused)
            .font(NSFont.systemFont(ofSize: NSFont.systemFontSize))
            .focused($focused)
            .environmentObject(HashtagViewModel(cabinet: OkamuraCabinet.shared))
    }
}
