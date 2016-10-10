/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

extension NSAttributedString {

    /**
     Method returns an attributed string with the letter spacing, linespacing, and centered defined by the parameters

     - parameter string:        String
     - parameter letterSpacing: CGFloat
     - parameter lineSpacing:   CGFloat
     - parameter centered:      Bool

     - returns: NSAttributedString
     */
    class func createAttributedStringWithLetterAndLineSpacingWithCentering(_ string: String, letterSpacing: CGFloat, lineSpacing: CGFloat, centered: Bool) -> NSAttributedString {

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSKernAttributeName, value:   letterSpacing, range: NSRange(location: 0, length: attributedString.length))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        if centered {
            paragraphStyle.alignment = NSTextAlignment.center
        }

        attributedString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

        return attributedString

    }

}
