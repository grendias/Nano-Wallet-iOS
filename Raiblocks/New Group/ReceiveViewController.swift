//
//  Copyright © 2017 Nano. All rights reserved.
//

import UIKit
import Photos

import Cartography
import Crashlytics
import EFQRCode

struct ReceiveViewModel {
    let address: Address
}

class ReceiveViewController: UIViewController {

    let viewModel: ReceiveViewModel

    var shareCard: SharableView?

    init(viewModel: ReceiveViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        Answers.logCustomEvent(withName: "Receive VC Viewed")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // TODO: add pan gesture recgnizer
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // MARK: - Navigation Controller Setup

        navigationController?.navigationBar.tintColor = Styleguide.Colors.lightBlue.color
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: Styleguide.Colors.darkBlue.color,
            .font: Styleguide.Fonts.sofiaRegular.font(ofSize: 17),
            .kern: 5.0
        ]

        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.shadowImage = UIImage() // hide the bottom border

        self.navigationItem.titleView = SendReceiveHeaderView(withType: .receive)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "dismissBlack"), style: .plain, target: self, action: #selector(dismissVC))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "share"), style: .plain, target: self, action: #selector(share(_:)))

        // MARK: - UI Elements

        let scanLabel = UILabel()
        scanLabel.numberOfLines = 2
        scanLabel.textAlignment = .center
        scanLabel.text = """
        Scan the QR code
        to receive NANO
        """
        scanLabel.lineBreakMode = .byWordWrapping
        scanLabel.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 20)
        scanLabel.textColor = Styleguide.Colors.darkBlue.color
        view.addSubview(scanLabel)
        constrain(scanLabel) {
            $0.width == $0.superview!.width * CGFloat(0.5)
            $0.centerX == $0.superview!.centerX
            $0.top == $0.superview!.top + CGFloat(55)
        }

        let qr = EFQRCode.generate(
            content: viewModel.address.longAddress,
            backgroundColor: UIColor.white.coreImageColor,
            foregroundColor: Styleguide.Colors.darkBlue.color.coreImageColor,
            watermark: UIImage(named: "largeNanoMarkBlue")?.cgImage,
            watermarkMode: .scaleAspectFit
        )!

        let imageView = UIImageView(image: UIImage(cgImage: qr))
        view.addSubview(imageView)
        constrain(imageView, scanLabel) {
            $0.width == $0.superview!.width * CGFloat(0.55)
            $0.height == $0.superview!.width * CGFloat(0.55)
            $0.top == $1.bottom + CGFloat(36)
            $0.centerX == $1.centerX
        }

        // MARK: - Bottom Section

        let copyButton = NanoButton(withType: .lightBlue)
        copyButton.addTarget(self, action: #selector(copyAddress), for: .touchUpInside)
        copyButton.setAttributedTitle("Copy".uppercased())
        view.addSubview(copyButton)
        constrain(copyButton) {
            $0.height == CGFloat(55)
            $0.width == $0.superview!.width * CGFloat(0.80)
            $0.bottom == $0.superview!.bottom - CGFloat((isiPhoneX() ? 34 : 20))
            $0.centerX == $0.superview!.centerX
        }

        let addressLabelHolder = UIView()
        addressLabelHolder.backgroundColor = Styleguide.Colors.darkBlue.color
        addressLabelHolder.layer.cornerRadius = 3
        addressLabelHolder.clipsToBounds = true
        view.addSubview(addressLabelHolder)
        constrain(addressLabelHolder, copyButton) {
            $0.bottom == $1.top - CGFloat(18)
            $0.width == $0.superview!.width * CGFloat(0.80)
            $0.centerX == $0.superview!.centerX
        }

        let addressLabel = UILabel()
        addressLabel.attributedText = viewModel.address.longAddressWithColorOnDarkBG
        addressLabel.numberOfLines = 10
        addressLabel.textAlignment = .center
        addressLabel.lineBreakMode = .byCharWrapping
        addressLabel.font = Styleguide.Fonts.nunitoRegular.font(ofSize: 16)
        addressLabelHolder.addSubview(addressLabel)
        constrain(addressLabel) {
            $0.top == $0.superview!.top + CGFloat(15)
            $0.bottom == $0.superview!.bottom - CGFloat(15)
            $0.left == $0.superview!.left + CGFloat(60)
            $0.right == $0.superview!.right - CGFloat(60)
        }

        let nanoAddressLabel = UILabel()
        nanoAddressLabel.attributedText = NSAttributedString(string: "NANO Address".uppercased(), attributes: [.kern: 5.0])
        nanoAddressLabel.textColor = Styleguide.Colors.darkBlue.color
        nanoAddressLabel.font = Styleguide.Fonts.sofiaRegular.font(ofSize: 16)
        view.addSubview(nanoAddressLabel)
        constrain(nanoAddressLabel, addressLabelHolder) {
            $0.centerX == $1.centerX
            $0.bottom == $1.top - CGFloat(18)
        }

        // TODO: make this pan, give it some fidelity
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissVC))
        gestureRecognizer.direction = .down
        view.addGestureRecognizer(gestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func copyAddress() {
        Answers.logCustomEvent(withName: "Nano Address Copied")

        UIPasteboard.general.string = viewModel.address.longAddress

        let ac = UIAlertController(title: "Your Nano Address Has Been Copied", message: "Share it with a friend to receive Nano!", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Done", style: .default))

        present(ac, animated: true, completion: nil)
    }

    @objc func share(_ button: UIButton) {
        Answers.logCustomEvent(withName: "Share Dialogue Viewed")

        var activityItems: [Any] = []

        activityItems = [viewModel.address.longAddress]

        let shareCard = SharableView(address: viewModel.address)
        let margin: CGFloat = 20
        let width = view.bounds.width - margin
        shareCard.frame = CGRect(x: (margin / 2), y: margin, width: width, height: (width / 2)) // TODO fix this on non-plus phones
        shareCard.alpha = 0
        self.shareCard = shareCard
        view.addSubview(shareCard)
        shareCard.setNeedsLayout()
        shareCard.layoutSubviews()
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: { self.shareCard?.alpha = 1 }, completion: nil)
        let sharableImage = shareCard.asImage()
        activityItems.append(sharableImage)

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = button
        activityViewController.excludedActivityTypes = [.assignToContact, .addToReadingList, .markupAsPDF, .openInIBooks, .postToVimeo]
        activityViewController.completionWithItemsHandler = { activityType, _, _, _ -> Void in
            if let type = activityType, case .saveToCameraRoll = type {
                PHPhotoLibrary.requestAuthorization {
                    guard $0 == .authorized else {
                        DispatchQueue.main.sync {
                            self.removeShareCard()
                        }

                        return
                    }
                }
            }

            self.removeShareCard()
        }

        present(activityViewController, animated: true, completion: nil)
    }

    private func removeShareCard() {
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
            self.shareCard?.alpha = 0
        }) { _ in
            self.shareCard?.removeFromSuperview()
        }
    }

    @objc func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
}
