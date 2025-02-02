//
//  ContentView.swift
//  NoctiLabs Watch App
//
//  Created by Jonathan Mitchell on 1/25/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SleepDashboardView()
                .tabItem {
                    Label("Sleep", systemImage: "bed.double.fill")
                }
            
            ActivityDashboardView()
                .tabItem {
                    Label("Activity", systemImage: "figure.walk")
                }
        }
        .tabViewStyle(PageTabViewStyle()) // Enables horizontal swiping
    }
}

#Preview {
    ContentView()
}
