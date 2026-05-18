//
//  SmallNativeAdFactory.swift
//  Runner
//
//  Matches Android `smallNativeAd` — single horizontal row: icon + text
//  column + CTA button. No media.
//
//  Khớp `smallNativeAd` của Android — 1 hàng ngang: icon + cột text +
//  button CTA. Không có media.
//

import Foundation
import UIKit
import google_mobile_ads

class SmallNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let v = NativeAdView()
        v.backgroundColor = .white

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        v.iconView = icon

        let badge = makeAdBadge()

        let headline = UILabel()
        headline.font = .systemFont(ofSize: 12, weight: .medium)
        headline.textColor = .black
        headline.numberOfLines = 1
        v.headlineView = headline

        let headlineRow = UIStackView(arrangedSubviews: [badge, headline])
        headlineRow.axis = .horizontal
        headlineRow.alignment = .center
        headlineRow.spacing = 4

        let body = UILabel()
        body.font = .systemFont(ofSize: 10)
        body.textColor = .darkGray
        body.numberOfLines = 2
        v.bodyView = body

        let textColumn = UIStackView(arrangedSubviews: [headlineRow, body])
        textColumn.axis = .vertical
        textColumn.spacing = 2
        textColumn.alignment = .leading

        let button = makeCallToActionButton(fontSize: 14, height: 32)
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        v.callToActionView = button

        let mainRow = UIStackView(arrangedSubviews: [icon, textColumn, button])
        mainRow.axis = .horizontal
        mainRow.spacing = 8
        mainRow.alignment = .center
        mainRow.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(mainRow)

        NSLayoutConstraint.activate([
            mainRow.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            mainRow.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            mainRow.topAnchor.constraint(equalTo: v.topAnchor, constant: 8),
            mainRow.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -8),

            icon.widthAnchor.constraint(equalToConstant: 42),
            icon.heightAnchor.constraint(equalToConstant: 42),
        ])

        bindNativeAd(v, nativeAd)
        return v
    }
}
