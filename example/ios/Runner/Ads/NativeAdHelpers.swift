//
//  NativeAdHelpers.swift
//  Runner
//
//  Shared helpers + ButtonPosition enum reused across all native ad
//  factories. Kept separate so each factory file stays small.
//
//  Helper dùng chung + enum ButtonPosition cho mọi NativeAdFactory.
//  Tách riêng để mỗi factory file gọn nhẹ.
//

import Foundation
import UIKit
import google_mobile_ads

/// Vị trí của Call-To-Action button trong layout có cả media + button.
/// Position of the Call-To-Action button in layouts that have both
/// media + button.
enum ButtonPosition {
    case top
    case bottom
}

/// Build the small "Ad" badge rendered inline next to the headline.
/// Tạo badge "Ad" nhỏ render inline cạnh headline.
func makeAdBadge() -> UILabel {
    let label = UILabel()
    label.text = "Ad"
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 9, weight: .semibold)
    label.textColor = .white
    label.backgroundColor = UIColor(red: 0.85, green: 0.55, blue: 0.05, alpha: 1.0)
    label.layer.cornerRadius = 3
    label.clipsToBounds = true
    label.translatesAutoresizingMaskIntoConstraints = false
    label.widthAnchor.constraint(equalToConstant: 22).isActive = true
    label.heightAnchor.constraint(equalToConstant: 15).isActive = true
    return label
}

/// Standard Call-To-Action button. Used by every factory below.
/// Button Call-To-Action chuẩn dùng chung cho mọi factory bên dưới.
func makeCallToActionButton(fontSize: CGFloat = 16, height: CGFloat = 48) -> UIButton {
    let button = UIButton(type: .system)
    button.backgroundColor = .systemBlue
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: fontSize)
    button.layer.cornerRadius = 6
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: height).isActive = true
    return button
}

/// Bind a [NativeAd] payload onto the outlets already wired on [view].
/// Every factory ends its `createNativeAd(...)` with this call.
///
/// Gán nội dung [NativeAd] vào các outlet đã wire trên [view]. Mỗi
/// factory kết thúc `createNativeAd(...)` bằng call này.
func bindNativeAd(_ view: NativeAdView, _ ad: NativeAd) {
    (view.headlineView as? UILabel)?.text = ad.headline
    (view.bodyView as? UILabel)?.text = ad.body
    view.bodyView?.isHidden = ad.body == nil
    (view.callToActionView as? UIButton)?.setTitle(ad.callToAction, for: .normal)
    view.callToActionView?.isHidden = ad.callToAction == nil
    (view.iconView as? UIImageView)?.image = ad.icon?.image
    view.iconView?.isHidden = ad.icon == nil
    view.mediaView?.mediaContent = ad.mediaContent
    view.callToActionView?.isUserInteractionEnabled = false
    view.nativeAd = ad
}
