//
//  LegendItem.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//
import SwiftUI

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
