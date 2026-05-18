//
//  HomeNativeAdFactory.swift
//  Runner
//
//  Matches Android `homeNativeAd` — compact horizontal: media on the
//  left, icon + text + button column on the right.
//
//  Khớp `homeNativeAd` của Android — compact ngang: media bên trái,
//  cột icon + text + button bên phải.
//

import Foundation
import UIKit
import google_mobile_ads

class HomeNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let v = NativeAdView()
        v.backgroundColor = .white

        // Left: media
        let media = MediaView()
        media.translatesAutoresizingMaskIntoConstraints = false
        v.mediaView = media

        // Right: icon + (badge + headline + body) + button
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
        textColumn.spacing = 4

        let topRow = UIStackView(arrangedSubviews: [icon, textColumn])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .top

        let button = makeCallToActionButton(fontSize: 12, height: 32)
        v.callToActionView = button

        let rightColumn = UIStackView(arrangedSubviews: [topRow, button])
        rightColumn.axis = .vertical
        rightColumn.spacing = 8
        rightColumn.distribution = .fill

        let mainRow = UIStackView(arrangedSubviews: [media, rightColumn])
        mainRow.axis = .horizontal
        mainRow.spacing = 8
        mainRow.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(mainRow)

        NSLayoutConstraint.activate([
            mainRow.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 8),
            mainRow.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -8),
            mainRow.topAnchor.constraint(equalTo: v.topAnchor, constant: 8),
            mainRow.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -8),

            media.widthAnchor.constraint(equalToConstant: 140),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),
        ])

        bindNativeAd(v, nativeAd)
        return v
    }
}
