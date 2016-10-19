//
//  ImageFeedTableViewCell.swift
//  BluePic
//
//  Created by Taylor Franklin on 10/18/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit

class ImageFeedTableViewCell: UITableViewCell {

    //image view used to display image
    @IBOutlet weak var userImageView: UIImageView!

    @IBOutlet weak var captionTextView: UITextView!

    @IBOutlet weak var loadingView: UIView!

    @IBOutlet weak var photographerNameLabel: UILabel!

    @IBOutlet weak var numberOfTagsLabel: UILabel!

    @IBOutlet weak var timeSincePostedLabel: UILabel!

    @IBOutlet weak var topConstraint: NSLayoutConstraint!

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    //string that is added to the numberOfTagsLabel at the end if there are multiple tags
    fileprivate let kNumberOfTagsPostFix_MultipleTags = NSLocalizedString("Tags", comment: "")

    //String that is added to the numberOfTagsLabel at the end if there is one tag
    fileprivate let kNumberOfTagsPostFix_OneTag = NSLocalizedString("Tag", comment: "")

    var defaultAttributes = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 13.0)]

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = UITableViewCellSelectionStyle.none

        let style = NSMutableParagraphStyle()
        style.alignment = .center
        defaultAttributes[NSParagraphStyleAttributeName] = style
    }

    /// Method sets up the data for the profile collection view cell
    ///
    /// - parameter image: Image object to use for populating UI
    func setupDataWith(_ image: Image) {

        if let numOfTags = image.tags?.count {

            if numOfTags == 0 {
                self.numberOfTagsLabel.isHidden = true
            } else if numOfTags == 1 {
                self.numberOfTagsLabel.isHidden = false
                self.numberOfTagsLabel.text = "\(numOfTags)" + " " + self.kNumberOfTagsPostFix_OneTag
            } else {
                self.numberOfTagsLabel.isHidden = false
                self.numberOfTagsLabel.text = "\(numOfTags)" + " " + self.kNumberOfTagsPostFix_MultipleTags
            }

        } else {
            self.numberOfTagsLabel.isHidden = true
        }

        //set the image view's image
        self.setImageView(image.url, fileName: image.fileName)

        //label that displays the photos caption
        _ = self.setCaptionText(image: image)

        //set the time since posted label's text
        self.timeSincePostedLabel.text = Date.timeSinceDateString(image.timeStamp)

        //set the photographerNameLabel's text
        let ownerNameString = NSLocalizedString("by", comment: "") + " \(image.user.name)"
        self.photographerNameLabel.text = ownerNameString
    }

    func setCaptionText(image: Image) -> Bool {

        let cutoffLength = 40
        if image.caption == CameraDataManager.SharedInstance.kEmptyCaptionPlaceHolder {
            self.captionTextView.text = ""
            self.topConstraint.constant = 0
            self.bottomConstraint.constant = 0
            self.captionTextView.textContainerInset = UIEdgeInsets.zero

            self.captionTextView.isHidden = true
        } else if image.caption.characters.count >= cutoffLength {
            if !image.isExpanded {
                let moreText = "...more"

                let abc: String = (image.caption as NSString).substring(with: NSRange(location: 0, length: cutoffLength)) + moreText
                let attributedString = NSMutableAttributedString(string: abc, attributes: defaultAttributes)
                attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray, range: NSRange(location: cutoffLength, length: 7))
                self.captionTextView.attributedText = attributedString
            } else {
                self.captionTextView.attributedText = NSMutableAttributedString(string: image.caption, attributes: defaultAttributes)
            }
            return true
        } else {
            self.captionTextView.attributedText = NSMutableAttributedString(string: image.caption, attributes: defaultAttributes)
        }
        return false
    }


    /**
     Method sets up the image view with the url provided or a locally cached verion of the image

     - parameter url:      String?
     - parameter fileName: String?
     */
    func setImageView(_ url: String?, fileName: String?) {

        self.loadingView.isHidden = false

        //first try to set image view with locally cached image (from a photo the user has posted during the app session)
        let locallyCachedImage = self.tryToSetImageViewWithLocallyCachedImage(fileName)

        //then try to set the imageView with a url, using the locally cached image as the placeholder (if there is one)
        self.tryToSetImageViewWithURL(url, placeHolderImage: locallyCachedImage)

    }

    /**
     Method trys to set the image view with a locally cached image if there is one and then returns the locally cached image

     - parameter fileName: String?

     - returns: UIImage?
     */
    fileprivate func tryToSetImageViewWithLocallyCachedImage(_ fileName: String?) -> UIImage? {

        //check if file name and facebook user id aren't nil
        if let fName = fileName {

            //generate id which is a concatenation of the file name and facebook user id
            let id = fName + CurrentUser.facebookUserId

            //check to see if there is an image cached in the camera data manager's picturesTakenDuringAppSessionById cache
            if let img = BluemixDataManager.SharedInstance.imagesTakenDuringAppSessionById[id] {

                //hide loading placeholder view
                self.loadingView.isHidden = true

                //set image view's image to locally cached image
                self.userImageView.image = img

                return img
            }
        }
        return nil
    }

    /**
     Method trys to set the image view with a url to an image and sets the placeholder to a locally cached image if its not nil

     - parameter url:              String?
     - parameter placeHolderImage: UIImage?
     */
    fileprivate func tryToSetImageViewWithURL(_ url: String?, placeHolderImage: UIImage?) {

        let urlString = url ?? ""

        //check if string is empty, if it is, then its not a valid url
        if urlString != "" {

            //check if we can turn the string into a valid URL
            if let nsurl = URL(string: urlString) {

                //if placeHolderImage parameter isn't nil, then set image with URL and use placeholder image
                if let image = placeHolderImage {
                    self.setImageViewWithURLAndPlaceHolderImage(nsurl, placeHolderImage: image)
                }
                    //else dont use placeholder image and
                else {
                    self.setImageViewWithURL(nsurl)
                }
            }
        }
    }

    /**
     Method sets the imageView with a url to an image and uses a locally cached image

     - parameter url:              URL
     - parameter placeHolderImage: UIImage
     */
    fileprivate func setImageViewWithURLAndPlaceHolderImage(_ url: URL, placeHolderImage: UIImage) {

        self.userImageView.sd_setImage(with: url, placeholderImage: placeHolderImage, options: [.delayPlaceholder]) { image, error, cacheType, url in

            self.loadingView.isHidden = image != nil && error == nil

        }
    }

    /**
     Method sets the imageView with a url to an image using no placeholder

     - parameter url: URL
     */
    fileprivate func setImageViewWithURL(_ url: URL) {
        self.userImageView.sd_setImage(with: url) { (image, error, cacheType, url) in

            self.loadingView.isHidden = image != nil && error == nil

        }
    }
}
