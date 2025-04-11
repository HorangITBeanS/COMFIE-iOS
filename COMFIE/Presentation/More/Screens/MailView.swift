//
//  MailView.swift
//  COMFIE
//
//  Created by Anjin on 4/11/25.
//

import MessageUI
import SwiftUI

struct MailView: UIViewControllerRepresentable {
    var onDismiss: () -> Void
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer { parent.onDismiss() }
            
            if let error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let mailVC = MFMailComposeViewController()
        
        mailVC.mailComposeDelegate = context.coordinator
        mailVC.setToRecipients(["comfie.team@gmail.com"])
        mailVC.setSubject("COMFIE에게 문의하기")
        
        let body = ""
        mailVC.setMessageBody(body, isHTML: false)
        
        return mailVC
    }

    func updateUIViewController(
        _ uiViewController: MFMailComposeViewController,
        context: UIViewControllerRepresentableContext<MailView>
    ) { }
}
