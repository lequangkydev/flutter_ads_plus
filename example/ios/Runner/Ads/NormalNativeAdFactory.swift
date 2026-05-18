//
//  NormalNativeAdFactory.swift
//  Runner
//
//  Matches Android `topNormalNativeAd` / `bottomNormalNativeAd`. Also
//  reused for `topExtraNativeAd` / `bottomExtraNativeAd` in AppDelegate.
//
//  Khớp `topNormalNativeAd` / `bottomNormalNativeAd` của Android. Cũng
//  được tái dùng cho `topExtraNativeAd` / `bottomExtraNativeAd` trong
//  AppDelegate.
//

import Foundation
import UIKit
import google_mobile_ads

/// Full native layout: icon + headline + body + media + CTA button.
/// Button can be placed at top or bottom via [buttonPosition].
///
/// Layout full: icon + headline + body + media + button CTA. Button có
/// thể đặt trên hoặc dưới qua [buttonPosition].
class NormalNativeAdFactory: NSObject, FLTNativeAdFactory {
    private let position: ButtonPosition

    init(buttonPosition: ButtonPosition) {
        self.position = buttonPosition
        super.init()
    }

    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
        let v = NativeAdView()
        v.backgroundColor = .white

        // Icon (left of headline row)
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        v.iconView = icon

        // "Ad" badge + headline (horizontal row)
        let badge = makeAdBadge()
        let headline = UILabel()
        headline.font = .systemFont(ofSize: 15, weight: .medium)
        headline.textColor = .black
        headline.numberOfLines = 1
        v.headlineView = headline

        let headlineRow = UIStackView(arrangedSubviews: [badge, headline])
        headlineRow.axis = .horizontal
        headlineRow.alignment = .center
        headlineRow.spacing = 4

        // Body (under headline)
        let body = UILabel()
        body.font = .systemFont(ofSize: 13)
        body.textColor = .darkGray
        body.numberOfLines = 2
        v.bodyView = body

        let textColumn = UIStackView(arrangedSubviews: [headlineRow, body])
        textColumn.axis = .vertical
        textColumn.spacing = 4

        let infoRow = UIStackView(arrangedSubviews: [icon, textColumn])
        infoRow.axis = .horizontal
        infoRow.spacing = 8
        infoRow.alignment = .top

        // Media (large image / video)
        let media = MediaView()
        media.translatesAutoresizingMaskIntoConstraints = false
        v.mediaView = media

        // CTA button
        let button = makeCallToActionButton()
        v.callToActionView = button

        // Compose main column. Button-at-top vs button-at-bottom only
        // changes the order of items inside this stack.
        // Compose cột chính. Khác biệt button-trên vs button-dưới chỉ là
        // thứ tự item trong stack này.
        let columnContents: [UIView] = position == .top
            ? [button, infoRow, media]
            : [infoRow, media, button]
        let column = UIStackView(arrangedSubviews: columnContents)
        column.axis = .vertical
        column.spacing = 10
        column.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(column)

        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 12),
            column.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -12),
            column.topAnchor.constraint(equalTo: v.topAnchor, constant: 12),
            column.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -12),

            icon.widthAnchor.constraint(equalToConstant: 42),
            icon.heightAnchor.constraint(equalToConstant: 42),
            media.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])

        bindNativeAd(v, nativeAd)
        return v
    }
}
