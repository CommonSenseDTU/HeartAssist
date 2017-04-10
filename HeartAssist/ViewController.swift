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

    private func showConsentFlow(survey: Survey) {
        self.consentManager = ConsentFlowManager(resourceManager: self.resourceManager, survey: survey)
        
        let consentController = self.consentManager!.viewController
        self.consentManager?.delegate.consentCompletion = { (_ controller: UIViewController, _ user: Musli.User?, authRefreshToken: String?, _ error: Error?) in
            if let userError = error as? ResourceManager.UserCreationError {
                self.presentErrorWithOKButton(controller: controller,
                                              title: userError.localizedTitle,
                                              message: userError.localizedDescription)
            }
            guard user != nil else { return }
            consentController.dismiss(animated: true, completion: {
                guard let taskController = self.taskManager!.viewController(task: survey.task) else { return }
                self.taskManager?.start(task: survey.task)
                self.present(taskController, animated: false, completion: nil)
            })
        }
        self.present(consentController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.resourceManager.survey(id: surveyId) { (survey: Survey?, error: Error?) in
            guard error == nil else {
                var title = NSLocalizedString("Error", comment: "Unknown Error title")
                var message = NSLocalizedString("An error occurred, please try again later.", comment: "Unknown Error message")
                if let response = (error as? NSError)?.userInfo[AFRKNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse {
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

            guard let user: User = User().readFromSecureStore() as? User else {
                self.showConsentFlow(survey: survey!)
                return
            }
            guard let date = user.signature?.date else {
                self.showConsentFlow(survey: survey!)
                return
            }
            guard date >= survey!.consentDocument.modificationDateTime else {
                self.showConsentFlow(survey: survey!)
                return
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

