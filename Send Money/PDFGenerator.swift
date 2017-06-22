//
//  PDFGenerator.swift
//  Send Money
//
//  Created by Eric Marshall on 5/24/16.
//  Copyright © 2016 Eric Marshall. All rights reserved.
//

import Foundation
import MessageUI
import RealmSwift
import Material

class PDFGenerator {

    // Font for generating PDFs
    fileprivate static var fontName = "Helvetica"

    // Drawing Constants
    fileprivate static let pageWidth = 612
    fileprivate static let pageHeight = 792
    fileprivate static let MARGIN: CGFloat = 54
    fileprivate static let padding: CGFloat = 2.5

    // Table drawing constants
    fileprivate static let DATE_CELL_LEFT = MARGIN
    fileprivate static let DATE_CELL_WIDTH: CGFloat = 80
    fileprivate static let VENDOR_CELL_LEFT = DATE_CELL_LEFT + DATE_CELL_WIDTH
    fileprivate static let VENDOR_CELL_WIDTH: CGFloat = 113
    fileprivate static let DETAIL_CELL_LEFT = VENDOR_CELL_LEFT + VENDOR_CELL_WIDTH
    fileprivate static let DETAIL_CELL_WIDTH: CGFloat = 200
    fileprivate static let COST_CELL_LEFT = DETAIL_CELL_LEFT + DETAIL_CELL_WIDTH
    fileprivate static let COST_CELL_WIDTH: CGFloat = 111
    fileprivate static let FULL_WIDTH: CGFloat = CGFloat(pageWidth) - MARGIN * 2

    // Card drawing constants
    fileprivate static let CARD_WIDTH:CGFloat = 120
    fileprivate static let CARD_HEIGHT:CGFloat = 223
    fileprivate static let CARD_X_SPACING:CGFloat = 8
    fileprivate static let CARD_Y_SPACING:CGFloat = 9
    fileprivate static let MAX_CARD_PAGE:CGFloat = 12 // Maximum number of cards per page
    fileprivate static let MAX_CARD_ROW:CGFloat = 4 // Maximum number of cards per row


    static func generatePDF(_ report: Report) -> String {

        print("Generating PDF")

        let realm = try! Realm()
        let context: CGContext!
        var curYPos = MARGIN
        var curPage = 0

        // Get data for drawing PDF
        var expenses: [Expense] = []
        for expense in realm.objects(Expense.self).filter("reportID='\(report.id)'"){
            expenses.append(expense)
        }

        // Create date formatter and date string
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let paths: NSArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let pdfPath: String = (paths.object(at: 0) as AnyObject).appendingPathComponent("dime/\(df.string(from: Date()))_\(report.name).pdf")

        // Begin PDF Drawing
        UIGraphicsBeginPDFContextToFile(pdfPath, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        context = UIGraphicsGetCurrentContext()
        curPage += 1
        // Begin a new page for the report
        curYPos = beginNewPage(forReport: report, inContext: context, onPage: curPage)

        //=============================
        // Begin overview table drawing

        // Draw the "summary" line
        let attribs = TextAttribute.titleInfo.getAttributesWithColor(.darkGray, andAlignment: .center)[0]
        let height = getExpenseLineWrapHeightForStrings(["Summary"], withWidths: [FULL_WIDTH], attributes: attribs)
        drawText("Summary", inFrame: CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: height), withAttributes: attribs)
        curYPos += height


        // Draw the category headers for the table
        drawTableHeaderAtY(&curYPos, inContext: context)
        // Draw each expense
        for expense in expenses {
            // Start a new page if necessary
            if curYPos >= CGFloat(pageHeight) - (MARGIN * 2) {
                curPage += 1
                curYPos = beginNewPage(forReport: report, inContext: context, onPage: curPage)
                drawCardPageHeader(&curYPos, forReport: report, inContext: context)
                drawTableHeaderAtY(&curYPos, inContext: context)
            }
            // Draw the next row
            drawTableExpenseAtY(&curYPos, forExpense: expense, inContext: context)
        }
        drawTableCostSummaryAtY(&curYPos, forAmount: calculateTotalCost(forExpenses: expenses), inContext: context)
        // End overview table drawing
        //=============================

        // Start a new page
        curPage += 1
        curYPos = beginNewPage(forReport: report, inContext: context, onPage: curPage)

        //==============================
        // Begin individual card drawing
        var x = 0
        var y = 0
        for expense in expenses {
            drawExpenseCard(x, y, forExpense: expense, inContext: context)
            x += 1
            if (x == 4) {
                x = 0
                y += 1
                if (y == 3) {
                    y = 0
                    beginNewPage(forReport: report, inContext: context, onPage: curPage)
                }
            }
        }
        // End individual card drawing
        //==============================

        // End PDF Drawing
        UIGraphicsEndPDFContext()

        print("Done.")

        return pdfPath
    }

    /// Begins a new page to draw on in the PDF
    fileprivate static func beginNewPage(forReport report: Report, inContext context: CGContext, onPage pageNum: Int) -> CGFloat {
        UIGraphicsBeginPDFPage()
        var curYPos:CGFloat = MARGIN

        // Draw the page number
        let attribs = TextAttribute.titleLabel.getAttributesWithColor(.darkGray, andAlignment: .center)[0]
        let height = getExpenseLineWrapHeightForStrings(["Summary"], withWidths: [FULL_WIDTH], attributes: attribs)
        drawText("\(pageNum)", inFrame: CGRect(x: MARGIN, y: CGFloat(pageHeight) - MARGIN, width: FULL_WIDTH, height: height), withAttributes: attribs)

        // If it's the first page, draw the report title, otherwise do a page header
        if (pageNum == 1) {
            drawReportTitleAtY(&curYPos, forReport: report, inContext: context)
        } else {
            drawCardPageHeader(&curYPos, forReport: report, inContext: context)
        }
        return curYPos
    }


    /// Draw the title for the given report, at the given y-position (ON THE FIRST PAGE)
    fileprivate static func drawReportTitleAtY(_ curYPos: inout CGFloat, forReport report: Report, inContext context: CGContext) {

        // Attributes for the text items
        var labelAttribs = TextAttribute.titleLabel.getAttributesWithColor(Material.Color.grey.lighten1, andAlignment: .left)[0]
        var infoAttribs = TextAttribute.titleInfo.getAttributesWithColor(Material.Color.darkGray, andAlignment: .left)[0]

        // The height for text items
        var labelHeight = getExpenseLineWrapHeightForStrings(["Report:"], withWidths: [FULL_WIDTH], attributes: labelAttribs)
        var infoHeight = getExpenseLineWrapHeightForStrings([report.name], withWidths: [FULL_WIDTH], attributes: infoAttribs)

        // Draw the label and info
        drawText("Report:", inFrame: CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: labelHeight), withAttributes: labelAttribs)
        curYPos += labelHeight / 2
        drawText(report.name, inFrame: CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: infoHeight), withAttributes: infoAttribs)
        curYPos += infoHeight

        // Attributes for the text items
        labelAttribs = TextAttribute.titleLabel.getAttributesWithColor(Material.Color.grey.lighten1, andAlignment: .left)[0]
        infoAttribs = TextAttribute.titleInfo.getAttributesWithColor(Material.Color.darkGray, andAlignment: .left)[0]

        // The height for text items
        labelHeight = getExpenseLineWrapHeightForStrings(["Date:"], withWidths: [FULL_WIDTH], attributes: labelAttribs)
        infoHeight = getExpenseLineWrapHeightForStrings([report.name], withWidths: [FULL_WIDTH], attributes: infoAttribs)

        // Draw the label and info
        context.setFillColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        drawText("Date:", inFrame: CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: labelHeight), withAttributes: labelAttribs)
        curYPos += labelHeight / 2
        let df = DateFormatter()
        df.dateFormat = "MMM dd, yyyy"
        drawText(df.string(from: report.deleteDateAndTime as Date), inFrame: CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: infoHeight), withAttributes: infoAttribs)
        curYPos += labelHeight
    }

    /// Draw the Header for the report (NOT ON THE FIRST PAGE)
    fileprivate static func drawCardPageHeader(_ curYPos: inout CGFloat, forReport report: Report, inContext context: CGContext) {
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 612, height: 792))
        // Draw Report's name in top left
        let attribs = TextAttribute.titleInfo.getAttributesWithColor(.darkGray, andAlignment: .left)[0]
        let height = getExpenseLineWrapHeightForStrings([report.name], withWidths: [FULL_WIDTH], attributes: attribs)
        drawText(report.name, inFrame: CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: height), withAttributes: attribs)
        curYPos += height
        // Draw top bar on report
        context.fill(CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: 1))
    }

    fileprivate static func drawTableHeaderAtY(_ curYPos: inout CGFloat, inContext context: CGContext) {
        drawTableRowAtY(&curYPos, ofType: .header, inContext: context)
    }

    fileprivate static func drawTableExpenseAtY(_ curYPos: inout CGFloat, forExpense expense: Expense, inContext context: CGContext) {
        drawTableRowAtY(&curYPos, ofType: .expense, forExpense: expense, inContext: context)
    }

    fileprivate static func drawTableCostSummaryAtY(_ curYPos: inout CGFloat, forAmount totalCost: String, inContext context: CGContext){
        drawTableRowAtY(&curYPos, ofType: .costSummary, forAmount: totalCost, inContext: context)
    }

    fileprivate static func drawTableRowAtY(_ curYPos: inout CGFloat, ofType type: TableCellType, forExpense expense: Expense? = nil, forAmount totalCost: String? = nil, inContext context: CGContext) {
        let costString: String
        let dateString: String
        let vendorString: String
        let detailString: String
        let backgroundRGB: CGFloat
        let bottomBorderRGB: CGFloat
        let verticalBorderRGB: CGFloat
        let drawAllCells = type != .costSummary
        let height: CGFloat
        var textAttribs: [[String: AnyObject]]
        switch (type) {
            // Set the constants for the Header cells
            case .header:
                costString = "Cost"
                dateString = "Date"
                vendorString = "Vendor"
                detailString = "Details"
                backgroundRGB = 239 / 255
                verticalBorderRGB = backgroundRGB
                bottomBorderRGB = 0.5
                textAttribs = TextAttribute.tableRowHeader.getAttributesWithColor(.darkGray, andAlignment: .center, .center, .center, .center)
                height = getExpenseLineWrapHeightForStrings(["Cost"], withWidths: [COST_CELL_WIDTH], attributes: textAttribs[0])
            // Set the constants for the expense data cells
            case .expense:
                costString = expense!.cost
                dateString = expense!.date
                vendorString = expense!.vendor
                detailString = expense!.details
                backgroundRGB = 1.0
                verticalBorderRGB = 239/255
                bottomBorderRGB = 239/255
                textAttribs = TextAttribute.tableRowText.getAttributesWithColor(.darkGray, andAlignment: .left, .left, .left, .right)
                height = getExpenseLineWrapHeightForStrings([expense!.details, expense!.cost, expense!.vendor], withWidths: [DETAIL_CELL_WIDTH, COST_CELL_WIDTH, VENDOR_CELL_WIDTH], attributes: textAttribs[0])
            // Set the constants for the cost summary cell
            case .costSummary:
                costString = totalCost!
                dateString = ""
                vendorString = ""
                detailString = "Total:"
                verticalBorderRGB = 239/255
                bottomBorderRGB = 239/255
                backgroundRGB = 1.0
                textAttribs = TextAttribute.tableRowText.getAttributesWithColor(.darkGray, andAlignment: .right, .right)
                height = getExpenseLineWrapHeightForStrings([totalCost!], withWidths: [COST_CELL_WIDTH], attributes: textAttribs[1])
        }

        // Draw the background for the cell
        if (drawAllCells) {
            context.setFillColor(red: backgroundRGB, green: backgroundRGB, blue: backgroundRGB, alpha: 1.0)
            context.fill(CGRect(x: DATE_CELL_LEFT, y: CGFloat(curYPos), width: CGFloat(pageWidth) - 2 * MARGIN, height: height))
        } else {
            context.setFillColor(red: 199/255, green: 249/255, blue: 255/255, alpha: 1.0)
            context.fill(CGRect(x: COST_CELL_LEFT, y: CGFloat(curYPos), width: COST_CELL_WIDTH, height: height))
        }

        // Draw the vertical borders for the cells
        context.setFillColor(red: verticalBorderRGB, green: verticalBorderRGB, blue: verticalBorderRGB, alpha: 1.0)
        if (drawAllCells) {
            for xLoc in [DATE_CELL_LEFT, VENDOR_CELL_LEFT, DETAIL_CELL_LEFT, COST_CELL_LEFT, COST_CELL_LEFT + COST_CELL_WIDTH] {
                context.fill(CGRect(x: xLoc, y: curYPos, width: 1.0, height: height))
            }
        } else {
            context.fill(CGRect(x: COST_CELL_LEFT, y: curYPos, width: 1.0, height: height))
            context.fill(CGRect(x: COST_CELL_LEFT + COST_CELL_WIDTH, y: curYPos, width: 1.0, height: height))
        }

        // Draw the bottom borders for the cells
        context.setFillColor(red: bottomBorderRGB, green: bottomBorderRGB, blue: bottomBorderRGB, alpha: 1.0)
        if (drawAllCells) {
            context.fill(CGRect(x: MARGIN, y: curYPos + height, width: CGFloat(pageWidth) - 2 * MARGIN + 1.0, height: 1.0))
        } else {
            context.fill(CGRect(x: COST_CELL_LEFT, y: curYPos + height, width: COST_CELL_WIDTH + 1.0, height: 1.0))
        }

        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        if (drawAllCells) {
            let strings = [dateString, vendorString, detailString, costString]
            let xLocs   = [DATE_CELL_LEFT, VENDOR_CELL_LEFT, DETAIL_CELL_LEFT, COST_CELL_LEFT]
            let widths  = [DATE_CELL_WIDTH, VENDOR_CELL_WIDTH, DETAIL_CELL_WIDTH, COST_CELL_WIDTH]
            for i in 0 ..< strings.count {
                drawText(strings[i], inFrame: CGRect(x: xLocs[i] + padding, y: curYPos + padding, width: widths[i] - padding * 2, height: height - padding * 2), withAttributes: textAttribs[i])
            }
        } else {
            let strings = [detailString, costString]
            let xLocs   = [DETAIL_CELL_LEFT, COST_CELL_LEFT]
            let widths  = [DETAIL_CELL_WIDTH, COST_CELL_WIDTH]
            for i in 0 ..< strings.count {
                drawText(strings[i], inFrame: CGRect(x: xLocs[i] + padding, y: curYPos + padding, width: widths[i] - padding * 2, height: height - padding * 2), withAttributes: textAttribs[0])
            }
        }

        curYPos += height + 1.0
    }

    fileprivate static func getExpenseLineWrapHeightForStrings(_ strings: [String], withWidths widths: [CGFloat], attributes: [String: AnyObject]) -> CGFloat{
        assert(strings.count == widths.count)

        var height: CGFloat = 0
        var attrString: NSAttributedString
        var framesetter: CTFramesetter
        var suggestedSize: CGSize
        for i in 0 ..< strings.count {
            attrString = NSAttributedString(string: strings[i], attributes: attributes)
            framesetter = CTFramesetterCreateWithAttributedString(attrString)
            suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, strings[i].characters.count), nil, CGSize(width: CGFloat(widths[i] - padding * 2), height: CGFloat.greatestFiniteMagnitude), nil)
            if height < suggestedSize.height {
                height = suggestedSize.height
            }
        }
        return height + padding * 2
    }

    fileprivate static func drawExpenseCard(_ cMatX: Int, _ cMatY: Int, forExpense expense: Expense, inContext context: CGContext) {
        // Aspect ratio and height of the images on cards
        let aspectRatio: CGFloat = 0.75
        let imageHeight = Int(CGFloat(CARD_WIDTH) / aspectRatio)
        
        // The x and y positions of the current card on the page
        let xPos = Int(MARGIN) + cMatX * Int(CARD_WIDTH + CARD_X_SPACING)
        let yPos = 86 + cMatY * Int(CARD_HEIGHT + CARD_Y_SPACING)
        
        // If the expense has an image, crop it and draw it
        if let image = UIImage(data: expense.imageData as Data) {
            let croppedImg: UIImage?
            
            // If crop image to correct ratio based on the dimensions
            if image.size.width / image.size.height > aspectRatio {
                let height = image.size.height
                let width = height * aspectRatio
                let x = (image.size.width - width) / 2.0
                let y: CGFloat = 0.0
                croppedImg = image.crop(bounds: CGRect(x: x, y: y, width: width, height: height))
            } else {
                let width = image.size.width
                let height = width / aspectRatio
                let x: CGFloat = 0.0
                let y = (image.size.height - height) / 2
                croppedImg = image.crop(bounds: CGRect(x: x, y: y, width: width, height: height))
            }
            croppedImg?.draw(in: CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: imageHeight))
        } else {
            // Draw replacement image if there is no image available
            context.setFillColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
            context.fill(CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: imageHeight))
            let string = "No Photo"
            let attribs = TextAttribute.titleInfo.getAttributesWithColor(UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0), andAlignment: .center)[0]
            let height = getExpenseLineWrapHeightForStrings([string], withWidths: [CARD_WIDTH], attributes: attribs)
            drawText(string, inFrame: CGRect(x: xPos, y: yPos + (imageHeight - Int(height)) / 2, width: Int(CARD_WIDTH), height: Int(height)), withAttributes: attribs)
        }
        
        // Draw cell for expense
        context.setStrokeColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        context.stroke(CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: Int(CARD_HEIGHT)))
        context.stroke(CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: imageHeight))
        
        // Dimensions for half and full width text areas in the cell
        let cardMargin = 4
        let fullWidth = CARD_WIDTH
        let halfWidth = CARD_WIDTH / 2
        let halfMargins = halfWidth - CGFloat(cardMargin)
        
        // The y location to draw the text at -- Adjusted after each line of writing that's on its own
        var y = yPos + imageHeight
        
        var str = expense.vendor
        var attribs = TextAttribute.cardDetailText.getAttributesWithColor(.darkGray, andAlignment: .center)[0]
        var height = getExpenseLineWrapHeightForStrings([str], withWidths: [fullWidth], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos, y: y, width: Int(fullWidth), height: Int(height)), withAttributes: attribs)
        
        y += Int(height)
        
        str = expense.cost
        attribs = TextAttribute.cardDetailText.getAttributesWithColor(.gray, andAlignment: .right)[0]
        height = getExpenseLineWrapHeightForStrings([str], withWidths: [halfMargins], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos + Int(halfWidth), y: y, width: Int(halfMargins), height: Int(height)), withAttributes: attribs)
        
        str = expense.date
        attribs = TextAttribute.cardDetailText.getAttributesWithColor(.gray, andAlignment: .left)[0]
        height = getExpenseLineWrapHeightForStrings([str], withWidths: [halfMargins], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos + cardMargin, y: y, width: Int(halfMargins), height: Int(height)), withAttributes: attribs)
        
        y += Int(height)
        
        str = expense.details
        attribs = TextAttribute.cardDetailText.getAttributesWithColor(.darkGray, andAlignment: .left)[0]
        height = getExpenseLineWrapHeightForStrings([str], withWidths: [fullWidth - CGFloat(cardMargin)], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos + cardMargin / 2, y: y, width: Int(fullWidth - CGFloat(cardMargin)), height: Int(height)), withAttributes: attribs)
    }

    /// Calculates the total cost of all expenses in the list
    fileprivate static func calculateTotalCost(forExpenses expenses: [Expense]) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = NumberFormatter.Style.currency
        nf.locale = Locale(identifier: "en_US")
        var sum = 0.0
        for expense in expenses {
            sum += Double(nf.number(from: expense.cost)!)
        }
        return nf.string(from: NSNumber(floatLiteral: sum))!
    }

    fileprivate static func drawText(_ text: String, inFrame frameRect: CGRect, withAttributes attributes: [String: AnyObject]) {
        let stringRef: CFString = text as CFString

        // Prepare the text using a core framesetter
        let attributeRef: CFDictionary = attributes as CFDictionary
        let currentText: CFAttributedString = CFAttributedStringCreate(nil, stringRef, attributeRef)
        let framesetter: CTFramesetter = CTFramesetterCreateWithAttributedString(currentText)
        let framePath: CGMutablePath = CGMutablePath()
        framePath.addRect(frameRect)

        // Get the frame that will do the rendering
        let currentRange: CFRange = CFRangeMake(0, 0)
        let frameRef: CTFrame = CTFramesetterCreateFrame(framesetter, currentRange, framePath, nil)

        // Get the graphics context
        let currentContext = UIGraphicsGetCurrentContext()

        // Put the text matrix into a known state. This ensures
        // that no old scaling factors are left in place.
        currentContext!.textMatrix = CGAffineTransform.identity

        // Core Text draws from the bottom-left corner up, so flip
        // the current transform prior to drawing.
        let offset: CGFloat = (frameRect.origin.y * 2) + frameRect.size.height
        currentContext?.translateBy(x: 0, y: offset)
        currentContext?.scaleBy(x: 1.0, y: -1.0)

        // Draw the frame.
        CTFrameDraw(frameRef, currentContext!)

        // Reset the transform
        currentContext?.scaleBy(x: 1.0, y: -1.0)
        currentContext?.translateBy(x: 0, y: -offset)
    }

    fileprivate enum TextAttribute {
        case titleInfo
        case titleLabel
        case tableRowHeader
        case tableRowText
        case cardDetailText

        func getAttributesWithColor(_ color: UIColor, andAlignment alignments: NSTextAlignment...) -> [[String: AnyObject]] {
            var attribs: [[String: AnyObject]] = []
            switch (self) {
                case .titleInfo:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 16.0))
                    }
                case .titleLabel:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 10.0))
                    }
                case .tableRowHeader:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 12.0))
                    }
                case .tableRowText:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 10.0))
                    }
                case .cardDetailText:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 8.0))
                }
            }
            return attribs
        }

        fileprivate func getTextAttributes(_ justification : NSTextAlignment, color: UIColor, size: CGFloat) -> [String : AnyObject] {
            let font = UIFont(name: fontName, size: size)
            let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            textStyle.alignment = justification
            let textColor = color
            return [
                NSFontAttributeName : font!,
                NSForegroundColorAttributeName: textColor,
                NSParagraphStyleAttributeName: textStyle
            ]
        }
    }

    fileprivate enum TableCellType {
        case header
        case expense
        case costSummary
    }
}
