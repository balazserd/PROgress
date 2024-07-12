//
//  SupportEmailView.swift
//  PROgress
//
//  Created by Balázs Erdész on 12/07/2024.
//

import Foundation
import SwiftUI
import MessageUI

struct SupportEmailView: UIViewControllerRepresentable {
    typealias UIViewControllerType = MFMailComposeViewController

    var mailComposeResult: Binding<MFMailComposeResult?>?
    var sendingError: Binding<Error?>?

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailController = MFMailComposeViewController()
        mailController.setToRecipients(["ebuniapps@gmail.com"])
        mailController.setSubject("PROgress: issue report")
        mailController.setMessageBody("Please describe what the issue is below.", isHTML: false)

        mailController.mailComposeDelegate = context.coordinator

        return mailController
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No update is necessary
    }

    func makeCoordinator() -> Coordinator {
        SupportEmailView.Coordinator(with: self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var mailViewController: SupportEmailView

        init(with mailVC: SupportEmailView) {
            self.mailViewController = mailVC
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            self.mailViewController.mailComposeResult?.wrappedValue = result
            self.mailViewController.sendingError?.wrappedValue = error
        }
    }
}

#Preview {
    if MFMailComposeViewController.canSendMail() {
        SupportEmailView()
    } else {
        Text("cannot send mail!")
    }
}
