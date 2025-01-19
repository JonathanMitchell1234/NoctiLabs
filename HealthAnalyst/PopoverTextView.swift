//
//  PopoverTextView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//
import SwiftUI

struct PopoverTextView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            Text(content)
                .font(.body)
        }
        .padding()
        .background(Color(UIColor.systemGray5))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
