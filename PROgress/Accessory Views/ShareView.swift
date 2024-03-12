//
//  ShareView.swift
//  PROgress
//
//  Created by Balázs Erdész on 12/03/2024.
//

import SwiftUI

extension View {
    /// Presents a Share Sheet over a popover.
    func shareView(with activityItems: [Any], isPresented: Binding<Bool>) -> some View {
        popover(isPresented: isPresented) {
            ShareView(items: activityItems, isPresented: isPresented)
                .presentationDetents([.medium, .large])
        }
    }
}

struct ShareView: UIViewControllerRepresentable {
    var items: [Any]
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityController.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }
        
        return activityController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // no-op
    }
}

// MARK: - Preview
#Preview {
    struct PreviewView: View {
        @State var showShareView: Bool = false
        
        var body: some View {
            VStack {
                Button(action: {
                    showShareView = true
                }, label: {
                    Text(showShareView ? "Showing Popover..." : "Empty View")
                })
            }
            .shareView(with: [NSString("ShareThisString"), UIColor.green], isPresented: $showShareView)
        }
    }
    
    return PreviewView()
}
