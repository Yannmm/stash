//
//  CellContent.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import SwiftUI
import Kingfisher

struct CellContent: View {
    let entry: (any Entry)?
    
    var body: some View {
        HStack {
            Label {
                Text(entry?.name ?? "")
                    .font(.body)
                    .foregroundStyle(Color.text)
            } icon: {
                if let e = entry {
                    switch (e.icon) {
                    case .system(let name):
                        Image(systemName: name)
                            .foregroundStyle(Color.theme)
                    case .favicon(let url):
                        if let url = url {
                            KFImage.url(url)
                            //                                  .placeholder(placeholderImage)
                            //                                  .setProcessor(processor)
                                .loadDiskFileSynchronously()
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                            //                                  .lowDataModeSource(.network(lowResolutionURL))
                            //                                  .onProgress { receivedSize, totalSize in  }
                                .onSuccess { result in  }
                                .onFailure { error in }
                        } else {
                            Image(systemName: "globe.fill")
                                .foregroundStyle(Color.theme)
                        }
                    }
                } else {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(Color.theme)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
        }
    }
}

#Preview {
    //    CellContent(title: "This is good")
}
