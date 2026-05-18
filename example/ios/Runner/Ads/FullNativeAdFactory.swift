//
//  FullNativeAdFactory.swift
//  Runner
//
//  Matches Android `fullNativeAd` — fullscreen layout with dark
//  background, used as an overlay on top of app-open-resume.
//
//  Khớp `fullNativeAd` của Android — layout full-màn nền tối, dùng phủ
//  lên app-open-resume.
//

import Foundation
import UIKit
import google_mobile_ads

class FullNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let v = NativeAdView()
        v.backgroundColor = .black

        let media = MediaView()
        media.translatesAutoresizingMaskIntoConstraints = false
        v.mediaView = media

        let badge = makeAdBadge()

        let headline = UILabel()
        headline.font = .systemFont(ofSize: 18, weight: .semibold)
        headline.textColor = .white
        headline.numberOfLines = 1
        v.headlineView = headline

        let body = UILabel()
        body.font = .systemFont(ofSize: 14)
        body.textColor = .lightGray
        body.numberOfLines = 3
        v.bodyView = body

        let button = makeCallToActionButton()
        v.callToActionView = button

        let column = UIStackView(arrangedSubviews: [media, badge, headline, body, button])
        column.axis = .vertical
        column.spacing = 12
        column.alignment = .leading
        column.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(column)

        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            column.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            column.centerYAnchor.constraint(equalTo: v.centerYAnchor),

            // Stretch media + button to the full column width.
            // Stretch media + button full chiều ngang của column.
            media.leadingAnchor.constraint(equalTo: column.leadingAnchor),
            media.trailingAnchor.constraint(equalTo: column.trailingAnchor),
            media.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),

            button.leadingAnchor.constraint(equalTo: column.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: column.trailingAnchor),
        ])

        bindNativeAd(v, nativeAd)
        return v
    }
}
