//
//  PrivacyProtectionOverviewController.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
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
//

import UIKit
import Core

class PrivacyProtectionOverviewController: UITableViewController {
    
    let privacyPracticesImages: [PrivacyPractices.Summary: UIImage] = [
        .unknown: #imageLiteral(resourceName: "PP Icon Privacy Bad Off"),
        .poor: #imageLiteral(resourceName: "PP Icon Privacy Bad On"),
        .mixed: #imageLiteral(resourceName: "PP Icon Privacy Good Off"),
        .good: #imageLiteral(resourceName: "PP Icon Privacy Good On")
    ]
    
    @IBOutlet var margins: [NSLayoutConstraint]!
    
    @IBOutlet weak var encryptionCell: SummaryCell!
    @IBOutlet weak var trackersCell: SummaryCell!
    @IBOutlet weak var privacyPracticesCell: SummaryCell!
    
    fileprivate var popRecognizer: InteractivePopRecognizer!
    
    private var siteRating: SiteRating!
    private var contentBlockerConfiguration = AppDependencyProvider.shared.storageCache.current.configuration
    private weak var header: PrivacyProtectionHeaderController!
    private weak var footer: PrivacyProtectionFooterController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initPopRecognizer()
        adjustMargins()
        
        update()

        applyTheme(ThemeManager.shared.currentTheme)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let displayInfo = segue.destination as? PrivacyProtectionInfoDisplaying {
            displayInfo.using(siteRating: siteRating, configuration: contentBlockerConfiguration)
        }
        
        if let header = segue.destination as? PrivacyProtectionHeaderController {
            self.header = header
        }
        
        if let footer = segue.destination as? PrivacyProtectionFooterController {
            self.footer = footer
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "Leaderboard" && !NetworkLeaderboard.shared.shouldShow() {
            return false
        }
        
        return true
    }

    private func update() {
        // not keen on this, but there seems to be a race condition when the site rating is updated and the controller hasn't be loaded yet
        guard isViewLoaded else { return }
        
        header.using(siteRating: siteRating, configuration: contentBlockerConfiguration)
        updateEncryption()
        updateTrackers()
        updatePrivacyPractices()
    }
    
    private func updateEncryption() {
        
        encryptionCell.summaryLabel.text = siteRating.encryptedConnectionText()
        switch siteRating.encryptionType {
            
        case .encrypted:
            encryptionCell.summaryImage.image = #imageLiteral(resourceName: "PP Icon Connection On")
            
        case .forced:
            encryptionCell.summaryImage.image = #imageLiteral(resourceName: "PP Icon Connection On")
            
        case .mixed:
            encryptionCell.summaryImage.image = #imageLiteral(resourceName: "PP Icon Connection Off")
            
        case .unencrypted:
            encryptionCell.summaryImage.image = #imageLiteral(resourceName: "PP Icon Connection Bad")
            
        }
        
    }
    
    private func updateTrackers() {
        trackersCell.summaryLabel.text = siteRating.networksText(configuration: contentBlockerConfiguration)
        
        if protecting() || siteRating.uniqueTrackersDetected == 0 {
            trackersCell.summaryImage.image = #imageLiteral(resourceName: "PP Icon Major Networks On")
        } else {
            trackersCell.summaryImage.image = #imageLiteral(resourceName: "PP Icon Major Networks Bad")
        }
        
    }
    
    private func updatePrivacyPractices() {
        privacyPracticesCell.summaryLabel.text = siteRating.privacyPracticesText()
        privacyPracticesCell.summaryImage.image = privacyPracticesImages[siteRating.privacyPracticesSummary()]
    }
    
    private func protecting() -> Bool {
        return contentBlockerConfiguration.protecting(domain: siteRating.domain)
    }
    
    // see https://stackoverflow.com/a/41248703
    private func initPopRecognizer() {
        guard let controller = navigationController else { return }
        popRecognizer = InteractivePopRecognizer(controller: controller)
        controller.interactivePopGestureRecognizer?.delegate = popRecognizer
    }
    
    private func adjustMargins() {
        if #available(iOS 10, *) {
            for margin in margins {
                margin.constant = 0
            }
        }
    }
    
}

extension PrivacyProtectionOverviewController: PrivacyProtectionInfoDisplaying {
    
    func using(siteRating: SiteRating, configuration: ContentBlockerConfigurationStore) {
        self.siteRating = siteRating
        self.contentBlockerConfiguration = configuration
        update()
    }
    
}

class SummaryCell: UITableViewCell {
    
    @IBOutlet weak var summaryImage: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!
    
}

class ProtectionUpgradedView: UIView {
    
    @IBOutlet weak var fromImage: UIImageView!
    @IBOutlet weak var toImage: UIImageView!
    
    func update(with siteRating: SiteRating) {
        let siteGradeImages = siteRating.siteGradeImages()
        fromImage.image = siteGradeImages.from
        toImage.image = siteGradeImages.to
    }
    
}

private class InteractivePopRecognizer: NSObject, UIGestureRecognizerDelegate {
    
    var navigationController: UINavigationController
    
    init(controller: UINavigationController) {
        self.navigationController = controller
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController.viewControllers.count > 1
    }
    
    // This is necessary because without it, subviews of your top controller can
    // cancel out your gesture recognizer on the edge.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension PrivacyProtectionOverviewController: Themable {

    func decorate(with theme: Theme) {
        setNeedsStatusBarAppearanceUpdate()
        decorateNavigationBar(with: theme)
    }
}
