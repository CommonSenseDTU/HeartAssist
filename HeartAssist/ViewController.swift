//
//  ViewController.swift
//  HeartAssist
//
//  Created by Anders Borch on 4/10/17.
//  Copyright © 2017 DTU. All rights reserved.
//

import UIKit
import Musli
import RestKit
import Locksmith
import Granola

let secret = "7b66-4479-97d9-02d3253bb5c5"
let surveyId = "17028160-1dd1-11e7-a5e7-4b5722ebfb6d"

class ViewController: UIViewController {

    let resourceManager = ResourceManager(clientSecret: secret)
    var consentManager: ConsentFlowManager?
    var taskManager: TaskFlowManager?
    
    private func presentErrorWithOKButton(controller: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK alert button"),
                                      style: .default,
                                      handler: { (action) in
                                        alert.dismiss(animated: true, completion: nil)
        }))
        controller.present(alert, animated: true, completion: nil)
    }
    
    private func showConsentFlow(survey: Survey, registerUser: Bool) {
        self.consentManager = ConsentFlowManager(resourceManager: self.resourceManager, survey: survey)
        let consentController = self.consentManager!.viewController(register: registerUser)
        self.consentManager?.delegate.existingUser = User.fromSecure()
        self.consentManager?.delegate.consentCompletion = { (_ controller: UIViewController, _ user: Musli.User?, _ error: Error?) in
            if let userError = error as? ResourceManager.UserCreationError {
                self.presentErrorWithOKButton(controller: controller,
                                              title: userError.localizedTitle,
                                              message: userError.localizedDescription)
            }
            guard user != nil else { return }
            
            do {
                do {
                    try user?.createInSecureStore()
                } catch {
                    try user?.updateInSecureStore()
                }
                UserDefaults.standard.set(user?.userId, forKey: "account")

                let consent = ORKConsent()
                if let uuid = UUID(uuidString: surveyId) {
                    consent.surveyId = uuid
                }
                if user?.signature != nil {
                    if let uuid = UUID(uuidString: user!.signature!.identifier) {
                        consent.signatureId = uuid
                    }
                }
                UserDefaults.standard.set(consent.data(), forKey: "consent")
                self.resourceManager.consent = consent
                
                consentController.dismiss(animated: true, completion: {
                    guard let taskController = self.taskManager!.viewController(task: survey.task) else { return }
                    self.taskManager?.start(task: survey.task)
                    self.present(taskController, animated: false, completion: nil)
                })
            } catch {
                let title = NSLocalizedString("Storage Error", comment: "Storage Error title")
                let message = NSLocalizedString("Could not save account information. Verify that you have enough free space", comment: "Storage Error message")
                self.presentErrorWithOKButton(controller: self,
                                              title: title,
                                              message: message)
            }
        }
        self.present(consentController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.resourceManager.survey(id: surveyId) { (survey: Survey?, error: Error?) in
            guard error == nil else {
                var title = NSLocalizedString("Error", comment: "Unknown Error title")
                var message = NSLocalizedString("An error occurred, please try again later.", comment: "Unknown Error message")
                if let response = (error as NSError?)?.userInfo[AFRKNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse {
                    if response.statusCode == 404 {
                        title = NSLocalizedString("Resource Not Found", comment: "404 Error title")
                        message = NSLocalizedString("The survey could not be found. Contact support or try again later.", comment: "404 Error message")
                    }
                }
                self.presentErrorWithOKButton(controller: self,
                                              title: title,
                                              message: message)
                return
            }
            guard survey != nil else {
                self.presentErrorWithOKButton(controller: self,
                                              title: NSLocalizedString("Survey Not Found", comment: "Survey Not Found error title"),
                                              message: NSLocalizedString("An error occurred, please try again later.", comment: "Survey Not Found error message"))
                return
            }
            
            self.taskManager = TaskFlowManager(resourceManager: self.resourceManager, survey: survey!)

            // Show consent flow if user has not been stored locally
            guard let user = User.fromSecure() else {
                self.showConsentFlow(survey: survey!, registerUser: true)
                return
            }
            // Show consent flow if there is no signature date
            guard let date = user.signature?.date else {
                self.showConsentFlow(survey: survey!, registerUser: true)
                return
            }
            /*
             Show consent flow if consent flow was updated on a later calendar date
             ResearchKit only stores signature date - not time, so we hope the 
             researcher won't update the consent document more than once per day...
             */
            guard Calendar.current.compare(date, to: survey!.consentDocument.modificationDateTime, toGranularity: Calendar.Component.day) != .orderedAscending else {
                self.showConsentFlow(survey: survey!, registerUser: false)
                return
            }
            
            guard let object = UserDefaults.standard.object(forKey: "consent") as? [AnyHashable: Any] else {
                self.showConsentFlow(survey: survey!, registerUser: false)
                return
            }
            self.resourceManager.consent = ORKConsent(data: object)
            
            guard user.userId != nil && user.password != nil else {
                // TODO: show login flow
                self.showConsentFlow(survey: survey!, registerUser: false)
                return
            }
            
            self.resourceManager.authorize(username: user.userId!, password: user.password!, completion: { (refreshToken: String?, error: Error?) in
                guard error == nil else {
                    let alert = UIAlertController(title: NSLocalizedString("Authorization Failed", comment: "Title in client error dialog"),
                                                  message: NSLocalizedString("Login failed, please authenticate again", comment: "Text in client error dialog"),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK alert button"),
                                                  style: .default,
                                                  handler: { (action) in
                                                    alert.dismiss(animated: true, completion: nil)
                                                    User.removeFromSecure()
                                                    self.showConsentFlow(survey: survey!, registerUser: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                guard let taskController = self.taskManager?.viewController(task: survey!.task) else { return }
                self.taskManager?.start(task: survey!.task)
                self.present(taskController, animated: false, completion: nil)
            })
        }
    }
}

