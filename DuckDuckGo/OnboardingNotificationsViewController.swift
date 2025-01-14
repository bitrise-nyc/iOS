//
//  OnboardingNotificationsViewController.swift
//  DuckDuckGo
//
//  Copyright © 2019 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import UIKit
import Core

class OnboardingNotificationsViewController: OnboardingContentViewController {
    
    override var continueButtonTitle: String {
        return UserText.onboardingNotificationsAccept
    }
    
    override var skipButtonTitle: String {
        return UserText.onboardingNotificationsDeny
    }
    
    override func onContinuePressed(navigationHandler: @escaping () -> Void) {
        
        LocalNotifications.shared.requestPermission { (enabled) in
            if enabled {
                Pixel.fire(pixel: .notificationOptIn)
            } else {
                Pixel.fire(pixel: .notificationOptOut)
            }
            
            LocalNotifications.shared.logic.didUpdateNotificationsPermissions(enabled: enabled)
            
            navigationHandler()
        }
    }
    
    override func onSkipPressed(navigationHandler: @escaping () -> Void) {
        Pixel.fire(pixel: .notificationOptOut)
        
        navigationHandler()
    }
    
}
