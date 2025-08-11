//
//  ContentView.swift
//  DaFom777
//
//  Created by IGOR on 05/08/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // This view is kept for compatibility but is no longer used
        // The app now starts with either OnboardingView or MainTabView
        // based on onboarding completion status
        Text("TaskMaster Pro")
            .font(.title)
            .foregroundColor(.appAccent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
    }
}

#Preview {
    ContentView()
}


