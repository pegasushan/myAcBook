//
//  SectionHeader .swift
//  myAcBook
//
//  Created by 한상욱 on 5/1/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground))
    }
}
