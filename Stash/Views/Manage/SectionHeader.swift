//
//  SectionHeader.swift
//  Stash
//
//  Created by Rayman on 2025/12/25.
//

import SwiftUI

extension ManageViewSidebar {
    struct SectionHeader: View {
        let title: String
        
        var body: some View {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.5)
        }
    }
}
