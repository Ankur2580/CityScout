//
//  ContentView.swift
//  CityScout
//
//  Created by Ankur Kothawade on 05/09/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SearchScreen(viewModel: AppSetupBuilder.makeSearchViewModel())
    }
}

#Preview {
    ContentView()
}
