//
//  ProgressVideosCollectionView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 16..
//

import SwiftUI

struct ProgressVideosCollectionView: View {
    @StateObject private var viewModel = ProgressVideosCollectionViewModel()
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ProgressVideosCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressVideosCollectionView()
    }
}
