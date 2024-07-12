//
//  SettingsViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 12/07/2024.
//

import Foundation
import MessageUI
import os
import SwiftUI
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var isShowingSubscriptionsSheet = false
    
    @Published var isShowingIssueReportMailSheet = false
    @Published var issueReportMailCompositionResult: MFMailComposeResult?
    @Published var isShowingIssueReportMailCompositionAlert = false
    @Published private(set) var issueReportMailCompositionAlertMessage: String?
    
    @Published var isShowingPrivacyPolicySheet = false

    init() {
        setupSubscriptions()
    }
    
    private var subscriptions = Set<AnyCancellable>()
    private func setupSubscriptions() {
        $issueReportMailCompositionResult
            .compactMap { $0?.userMessage }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userMessage in
                self?.issueReportMailCompositionAlertMessage = userMessage
                self?.isShowingIssueReportMailCompositionAlert = true
            }
            .store(in: &subscriptions)
    }
}

fileprivate extension MFMailComposeResult {
    var userMessage: String? {
        switch self {
        case .cancelled:
            return "If you encounter an error, you can always send an e-mail to ebuniapps@gmail.com."
            
        case .saved:
            return "Your message was saved. But don't forget, we are happy to hear from you anytime."
            
        case .sent:
            return "Your message was sent. We will get back to you as soon as we can."
            
        case .failed:
            return "Your message could not be sent. Please try again later."
            
        @unknown default:
            PRLogger.app.fault("Uncovered enumeration case in MFMailComposeResult!")
            return nil
        }
    }
}
