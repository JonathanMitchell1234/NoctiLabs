//
//  CircularProgressView.swift
//  HealthAnalyst
//
//  Created by Jonathan Mitchell on 1/18/25.
//
import SwiftUI

struct CircularProgressView: View {
    let percentage: CGFloat
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(Color.green, lineWidth: 10)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(percentage * 100))%")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 100, height: 100)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text(value)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
