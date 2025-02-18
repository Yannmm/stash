//
//  CellContent.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import SwiftUI

struct CellContent: View {
    let title: String
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.text)
            } icon: {
                Image(systemName: "folder.fill")
                    .foregroundStyle(Color.theme)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
        }
    }
}

#Preview {
    CellContent(title: "This is good")
}
