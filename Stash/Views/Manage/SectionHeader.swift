//
//  SectionHeader.swift
//  Stash
//
//  Created by Rayman on 2025/12/25.
//

import SwiftUI

extension ManageView.Sidebar {
    struct SectionHeader: View {
        let title: String
        
        var body: some View {
            
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 18)
                .padding(.bottom, 6)
            
        }
    }
}
