//
//  CounterView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/9.
//

import SwiftUI

struct CounterView: View {
    @State private var count: Int = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
        }
    }
}
