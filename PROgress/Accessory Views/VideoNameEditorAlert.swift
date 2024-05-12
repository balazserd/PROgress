//
//  VideoNameEditorAlert.swift
//  PROgress
//
//  Created by Balázs Erdész on 12/05/2024.
//

import SwiftUI

struct VideoNameEditorAlert: ViewModifier {
    @State private var editedVideoName = ""
    
    let isPresented: Binding<Bool>
    let videoName: Binding<String>
    
    func body(content: Content) -> some View {
        content.alert(
            "Change video title",
            isPresented: isPresented,
            actions: {
                TextField("Video Title", text: $editedVideoName)
                    .submitLabel(.done)
                    .onSubmit {
                        videoName.wrappedValue = editedVideoName
                        editedVideoName = ""
                        isPresented.wrappedValue = false
                    }
                Button("Cancel", role: .cancel, action: { isPresented.wrappedValue = false })
            },
            message: {
                Text("Change the name of your video. This is the name by which it will be saved and later shown to you.")
            })
    }
}

extension View {
    func videoNameEditorAlert(_ videoName: Binding<String>, isPresented: Binding<Bool>) -> some View {
        self.modifier(VideoNameEditorAlert(isPresented: isPresented, videoName: videoName))
    }
}
