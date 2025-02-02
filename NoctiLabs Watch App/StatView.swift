//
//  StatView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//

import SwiftUI

struct StatView: View {
    let title: String
    let value: String
    let percentage: String?
    let description: String?
    let icon: String?
    
    var body: some View {
        VStack {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.8))
                }
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            if let percentage = percentage {
                Text(percentage)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
//        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}
