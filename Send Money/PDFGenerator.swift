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
    private static var fontName = "Helvetica"

    // Drawing Constants
    private static let pageWidth = 612
    private static let pageHeight = 792
    private static let MARGIN: CGFloat = 54
    private static let padding: CGFloat = 2.5

    // Table drawing constants
    private static let DATE_CELL_LEFT = MARGIN
    private static let DATE_CELL_WIDTH: CGFloat = 80
    private static let VENDOR_CELL_LEFT = DATE_CELL_LEFT + DATE_CELL_WIDTH
    private static let VENDOR_CELL_WIDTH: CGFloat = 113
    private static let DETAIL_CELL_LEFT = VENDOR_CELL_LEFT + VENDOR_CELL_WIDTH
    private static let DETAIL_CELL_WIDTH: CGFloat = 200
    private static let COST_CELL_LEFT = DETAIL_CELL_LEFT + DETAIL_CELL_WIDTH
    private static let COST_CELL_WIDTH: CGFloat = 111
    private static let FULL_WIDTH: CGFloat = CGFloat(pageWidth) - MARGIN * 2

    // Card drawing constants
    private static let CARD_WIDTH:CGFloat = 120
    private static let CARD_HEIGHT:CGFloat = 223
    private static let CARD_X_SPACING:CGFloat = 8
    private static let CARD_Y_SPACING:CGFloat = 9
    private static let MAX_CARD_PAGE:CGFloat = 12 // Maximum number of cards per page
    private static let MAX_CARD_ROW:CGFloat = 4 // Maximum number of cards per row


    static func generatePDF(report: Report) -> String {

        let realm = try! Realm()
        let context: CGContext!
        var curYPos = MARGIN
        var curPage = 0

        // Get data for drawing PDF
        var expenses: [Expense] = []
        for expense in realm.objects(Expense).filter("reportID='\(report.id)'"){
            expenses.append(expense)
        }

        // Create date formatter and date string
        let df = NSDateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let paths: NSArray = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let pdfPath: String = paths.objectAtIndex(0).stringByAppendingPathComponent("Send_Money/\(df.stringFromDate(NSDate()))_\(report.name).pdf")

        // Begin PDF Drawing
        UIGraphicsBeginPDFContextToFile(pdfPath, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        context = UIGraphicsGetCurrentContext()
        curPage += 1
        // Begin a new page for the report
        curYPos = beginNewPage(forReport: report, inContext: context, onPage: curPage)

        //=============================
        // Begin overview table drawing

        // Draw the "summary" line
        let attribs = TextAttribute.TitleInfo.getAttributesWithColor(.darkGrayColor(), andAlignment: .Center)[0]
        let height = getExpenseLineWrapHeightForStrings(["Summary"], withWidths: [FULL_WIDTH], attributes: attribs)
        drawText("Summary", inFrame: CGRectMake(MARGIN, curYPos, FULL_WIDTH, height), withAttributes: attribs)
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
        return pdfPath
    }

    /// Begins a new page to draw on in the PDF
    private static func beginNewPage(forReport report: Report, inContext context: CGContext, onPage pageNum: Int) -> CGFloat {
        UIGraphicsBeginPDFPage()
        var curYPos:CGFloat = MARGIN

        // Draw the page number
        let attribs = TextAttribute.TitleLabel.getAttributesWithColor(.darkGrayColor(), andAlignment: .Center)[0]
        let height = getExpenseLineWrapHeightForStrings(["Summary"], withWidths: [FULL_WIDTH], attributes: attribs)
        drawText("\(pageNum)", inFrame: CGRectMake(MARGIN, CGFloat(pageHeight) - MARGIN, FULL_WIDTH, height), withAttributes: attribs)

        // If it's the first page, draw the report title, otherwise do a page header
        if (pageNum == 1) {
            drawReportTitleAtY(&curYPos, forReport: report, inContext: context)
        } else {
            drawCardPageHeader(&curYPos, forReport: report, inContext: context)
        }
        return curYPos
    }


    /// Draw the title for the given report, at the given y-position (ON THE FIRST PAGE)
    private static func drawReportTitleAtY(inout curYPos: CGFloat, forReport report: Report, inContext context: CGContext) {

        // Attributes for the text items
        var labelAttribs = TextAttribute.TitleLabel.getAttributesWithColor(MaterialColor.grey.lighten1, andAlignment: .Left)[0]
        var infoAttribs = TextAttribute.TitleInfo.getAttributesWithColor(.darkGrayColor(), andAlignment: .Left)[0]

        // The height for text items
        var labelHeight = getExpenseLineWrapHeightForStrings(["Report:"], withWidths: [FULL_WIDTH], attributes: labelAttribs)
        var infoHeight = getExpenseLineWrapHeightForStrings([report.name], withWidths: [FULL_WIDTH], attributes: infoAttribs)

        // Draw the label and info
        drawText("Report:", inFrame: CGRectMake(MARGIN, curYPos, FULL_WIDTH, labelHeight), withAttributes: labelAttribs)
        curYPos += labelHeight / 2
        drawText(report.name, inFrame: CGRectMake(MARGIN, curYPos, FULL_WIDTH, infoHeight), withAttributes: infoAttribs)
        curYPos += infoHeight

        // Attributes for the text items
        labelAttribs = TextAttribute.TitleLabel.getAttributesWithColor(MaterialColor.grey.lighten1, andAlignment: .Left)[0]
        infoAttribs = TextAttribute.TitleInfo.getAttributesWithColor(.darkGrayColor(), andAlignment: .Left)[0]

        // The height for text items
        labelHeight = getExpenseLineWrapHeightForStrings(["Date:"], withWidths: [FULL_WIDTH], attributes: labelAttribs)
        infoHeight = getExpenseLineWrapHeightForStrings([report.name], withWidths: [FULL_WIDTH], attributes: infoAttribs)

        // Draw the label and info
        CGContextSetRGBFillColor(context, 0.8, 0.8, 0.8, 1.0)
        drawText("Date:", inFrame: CGRectMake(MARGIN, curYPos, FULL_WIDTH, labelHeight), withAttributes: labelAttribs)
        curYPos += labelHeight / 2
        let df = NSDateFormatter()
        df.dateFormat = "MMM dd, yyyy"
        drawText(df.stringFromDate(report.deleteDateAndTime), inFrame: CGRectMake(MARGIN, curYPos, FULL_WIDTH, infoHeight), withAttributes: infoAttribs)
        curYPos += labelHeight
    }

    /// Draw the Header for the report (NOT ON THE FIRST PAGE)
    private static func drawCardPageHeader(inout curYPos: CGFloat, forReport report: Report, inContext context: CGContext) {
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0)
        CGContextFillRect(context, CGRect(x: 0, y: 0, width: 612, height: 792))
        // Draw Report's name in top left
        let attribs = TextAttribute.TitleInfo.getAttributesWithColor(.darkGrayColor(), andAlignment: .Left)[0]
        let height = getExpenseLineWrapHeightForStrings([report.name], withWidths: [FULL_WIDTH], attributes: attribs)
        drawText(report.name, inFrame: CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: height), withAttributes: attribs)
        curYPos += height
        // Draw top bar on report
        CGContextFillRect(context, CGRect(x: MARGIN, y: curYPos, width: FULL_WIDTH, height: 1))
    }

    private static func drawTableHeaderAtY(inout curYPos: CGFloat, inContext context: CGContext) {
        drawTableRowAtY(&curYPos, ofType: .Header, inContext: context)
    }

    private static func drawTableExpenseAtY(inout curYPos: CGFloat, forExpense expense: Expense, inContext context: CGContext) {
        drawTableRowAtY(&curYPos, ofType: .Expense, forExpense: expense, inContext: context)
    }

    private static func drawTableCostSummaryAtY(inout curYPos: CGFloat, forAmount totalCost: String, inContext context: CGContext){
        drawTableRowAtY(&curYPos, ofType: .CostSummary, forAmount: totalCost, inContext: context)
    }

    private static func drawTableRowAtY(inout curYPos: CGFloat, ofType type: TableCellType, forExpense expense: Expense? = nil, forAmount totalCost: String? = nil, inContext context: CGContext) {
        let costString: String
        let dateString: String
        let vendorString: String
        let detailString: String
        let backgroundRGB: CGFloat
        let bottomBorderRGB: CGFloat
        let verticalBorderRGB: CGFloat
        let drawAllCells = type != .CostSummary
        let height: CGFloat
        var textAttribs: [[String: AnyObject]]
        switch (type) {
            // Set the constants for the Header cells
            case .Header:
                costString = "Cost"
                dateString = "Date"
                vendorString = "Vendor"
                detailString = "Details"
                backgroundRGB = 239 / 255
                verticalBorderRGB = backgroundRGB
                bottomBorderRGB = 0.5
                textAttribs = TextAttribute.TableRowHeader.getAttributesWithColor(.darkGrayColor(), andAlignment: .Center, .Center, .Center, .Center)
                height = getExpenseLineWrapHeightForStrings(["Cost"], withWidths: [COST_CELL_WIDTH], attributes: textAttribs[0])
            // Set the constants for the expense data cells
            case .Expense:
                costString = expense!.cost
                dateString = expense!.date
                vendorString = expense!.vendor
                detailString = expense!.details
                backgroundRGB = 1.0
                verticalBorderRGB = 239/255
                bottomBorderRGB = 239/255
                textAttribs = TextAttribute.TableRowText.getAttributesWithColor(.darkGrayColor(), andAlignment: .Left, .Left, .Left, .Right)
                height = getExpenseLineWrapHeightForStrings([expense!.details, expense!.cost, expense!.vendor], withWidths: [DETAIL_CELL_WIDTH, COST_CELL_WIDTH, VENDOR_CELL_WIDTH], attributes: textAttribs[0])
            // Set the constants for the cost summary cell
            case .CostSummary:
                costString = totalCost!
                dateString = ""
                vendorString = ""
                detailString = "Total:"
                verticalBorderRGB = 239/255
                bottomBorderRGB = 239/255
                backgroundRGB = 1.0
                textAttribs = TextAttribute.TableRowText.getAttributesWithColor(.darkGrayColor(), andAlignment: .Right, .Right)
                height = getExpenseLineWrapHeightForStrings([totalCost!], withWidths: [COST_CELL_WIDTH], attributes: textAttribs[1])
        }

        // Draw the background for the cell
        if (drawAllCells) {
            CGContextSetRGBFillColor(context, backgroundRGB, backgroundRGB, backgroundRGB, 1.0)
            CGContextFillRect(context, CGRectMake(DATE_CELL_LEFT, CGFloat(curYPos), CGFloat(pageWidth) - 2 * MARGIN, height))
        } else {
            CGContextSetRGBFillColor(context, 199/255, 249/255, 255/255, 1.0)
            CGContextFillRect(context, CGRectMake(COST_CELL_LEFT, CGFloat(curYPos), COST_CELL_WIDTH, height))
        }

        // Draw the vertical borders for the cells
        CGContextSetRGBFillColor(context, verticalBorderRGB, verticalBorderRGB, verticalBorderRGB, 1.0)
        if (drawAllCells) {
            for xLoc in [DATE_CELL_LEFT, VENDOR_CELL_LEFT, DETAIL_CELL_LEFT, COST_CELL_LEFT, COST_CELL_LEFT + COST_CELL_WIDTH] {
                CGContextFillRect(context, CGRectMake(xLoc, curYPos, 1.0, height))
            }
        } else {
            CGContextFillRect(context, CGRectMake(COST_CELL_LEFT, curYPos, 1.0, height))
            CGContextFillRect(context, CGRectMake(COST_CELL_LEFT + COST_CELL_WIDTH, curYPos, 1.0, height))
        }

        // Draw the bottom borders for the cells
        CGContextSetRGBFillColor(context, bottomBorderRGB, bottomBorderRGB, bottomBorderRGB, 1.0)
        if (drawAllCells) {
            CGContextFillRect(context, CGRectMake(MARGIN, curYPos + height, CGFloat(pageWidth) - 2 * MARGIN + 1.0, 1.0))
        } else {
            CGContextFillRect(context, CGRectMake(COST_CELL_LEFT, curYPos + height, COST_CELL_WIDTH + 1.0, 1.0))
        }

        CGContextSetRGBFillColor(context, 0, 0, 0, 1.0)
        if (drawAllCells) {
            let strings = [dateString, vendorString, detailString, costString]
            let xLocs   = [DATE_CELL_LEFT, VENDOR_CELL_LEFT, DETAIL_CELL_LEFT, COST_CELL_LEFT]
            let widths  = [DATE_CELL_WIDTH, VENDOR_CELL_WIDTH, DETAIL_CELL_WIDTH, COST_CELL_WIDTH]
            for i in 0 ..< strings.count {
                drawText(strings[i], inFrame: CGRectMake(xLocs[i] + padding, curYPos + padding, widths[i] - padding * 2, height - padding * 2), withAttributes: textAttribs[i])
            }
        } else {
            let strings = [detailString, costString]
            let xLocs   = [DETAIL_CELL_LEFT, COST_CELL_LEFT]
            let widths  = [DETAIL_CELL_WIDTH, COST_CELL_WIDTH]
            for i in 0 ..< strings.count {
                drawText(strings[i], inFrame: CGRectMake(xLocs[i] + padding, curYPos + padding, widths[i] - padding * 2, height - padding * 2), withAttributes: textAttribs[0])
            }
        }

        curYPos += height + 1.0
    }

    private static func getExpenseLineWrapHeightForStrings(strings: [String], withWidths widths: [CGFloat], attributes: [String: AnyObject]) -> CGFloat{
        assert(strings.count == widths.count)

        var height: CGFloat = 0
        var attrString: NSAttributedString
        var framesetter: CTFramesetterRef
        var suggestedSize: CGSize
        for i in 0 ..< strings.count {
            attrString = NSAttributedString(string: strings[i], attributes: attributes)
            framesetter = CTFramesetterCreateWithAttributedString(attrString)
            suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, strings[i].characters.count), nil, CGSizeMake(CGFloat(widths[i] - padding * 2), CGFloat.max), nil)
            if height < suggestedSize.height {
                height = suggestedSize.height
            }
        }
        return height + padding * 2
    }

    private static func drawExpenseCard(cMatX: Int, _ cMatY: Int, forExpense expense: Expense, inContext context: CGContext) {
        // Aspect ratio and height of the images on cards
        let aspectRatio: CGFloat = 0.75
        let imageHeight = Int(CGFloat(CARD_WIDTH) / aspectRatio)
        
        // The x and y positions of the current card on the page
        let xPos = Int(MARGIN) + cMatX * Int(CARD_WIDTH + CARD_X_SPACING)
        let yPos = 86 + cMatY * Int(CARD_HEIGHT + CARD_Y_SPACING)
        
        // If the expense has an image, crop it and draw it
        if let image = UIImage(data: expense.imageData) {
            let croppedImg: UIImage?
            
            // If crop image to correct ratio based on the dimensions
            if image.size.width / image.size.height > aspectRatio {
                let height = image.size.height
                let width = height * aspectRatio
                let x = (image.size.width - width) / 2.0
                let y: CGFloat = 0.0
                croppedImg = image.crop(CGRect(x: x, y: y, width: width, height: height))
            } else {
                let width = image.size.width
                let height = width / aspectRatio
                let x: CGFloat = 0.0
                let y = (image.size.height - height) / 2
                croppedImg = image.crop(CGRect(x: x, y: y, width: width, height: height))
            }
            croppedImg?.drawInRect(CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: imageHeight))
        } else {
            // Draw replacement image if there is no image available
            CGContextSetRGBFillColor(context, 0.97, 0.97, 0.97, 1.0)
            CGContextFillRect(context, CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: imageHeight))
            let string = "No Photo"
            let attribs = TextAttribute.TitleInfo.getAttributesWithColor(UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0), andAlignment: .Center)[0]
            let height = getExpenseLineWrapHeightForStrings([string], withWidths: [CARD_WIDTH], attributes: attribs)
            drawText(string, inFrame: CGRect(x: xPos, y: yPos + (imageHeight - Int(height)) / 2, width: Int(CARD_WIDTH), height: Int(height)), withAttributes: attribs)
        }
        
        // Draw cell for expense
        CGContextSetRGBStrokeColor(context, 0.8, 0.8, 0.8, 1.0)
        CGContextStrokeRect(context, CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: Int(CARD_HEIGHT)))
        CGContextStrokeRect(context, CGRect(x: xPos, y: yPos, width: Int(CARD_WIDTH), height: imageHeight))
        
        // Dimensions for half and full width text areas in the cell
        let cardMargin = 4
        let fullWidth = CARD_WIDTH
        let halfWidth = CARD_WIDTH / 2
        let halfMargins = halfWidth - CGFloat(cardMargin)
        
        // The y location to draw the text at -- Adjusted after each line of writing that's on its own
        var y = yPos + imageHeight
        
        var str = expense.vendor
        var attribs = TextAttribute.CardDetailText.getAttributesWithColor(.darkGrayColor(), andAlignment: .Center)[0]
        var height = getExpenseLineWrapHeightForStrings([str], withWidths: [fullWidth], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos, y: y, width: Int(fullWidth), height: Int(height)), withAttributes: attribs)
        
        y += Int(height)
        
        str = expense.cost
        attribs = TextAttribute.CardDetailText.getAttributesWithColor(.grayColor(), andAlignment: .Right)[0]
        height = getExpenseLineWrapHeightForStrings([str], withWidths: [halfMargins], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos + Int(halfWidth), y: y, width: Int(halfMargins), height: Int(height)), withAttributes: attribs)
        
        str = expense.date
        attribs = TextAttribute.CardDetailText.getAttributesWithColor(.grayColor(), andAlignment: .Left)[0]
        height = getExpenseLineWrapHeightForStrings([str], withWidths: [halfMargins], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos + cardMargin, y: y, width: Int(halfMargins), height: Int(height)), withAttributes: attribs)
        
        y += Int(height)
        
        str = expense.details
        attribs = TextAttribute.CardDetailText.getAttributesWithColor(.darkGrayColor(), andAlignment: .Left)[0]
        height = getExpenseLineWrapHeightForStrings([str], withWidths: [fullWidth - CGFloat(cardMargin)], attributes: attribs)
        drawText(str, inFrame: CGRect(x: xPos + cardMargin / 2, y: y, width: Int(fullWidth - CGFloat(cardMargin)), height: Int(height)), withAttributes: attribs)
    }

    /// Calculates the total cost of all expenses in the list
    private static func calculateTotalCost(forExpenses expenses: [Expense]) -> String {
        let nf = NSNumberFormatter()
        nf.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        nf.locale = NSLocale(localeIdentifier: "en_US")
        var sum = 0.0
        for expense in expenses {
            sum += Double(nf.numberFromString(expense.cost)!)
        }
        return nf.stringFromNumber(sum)!
    }

    private static func drawText(text: String, inFrame frameRect: CGRect, withAttributes attributes: [String: AnyObject]) {
        let stringRef: CFString = text

        // Prepare the text using a core framesetter
        let attributeRef: CFDictionaryRef = attributes
        let currentText: CFAttributedStringRef = CFAttributedStringCreate(nil, stringRef, attributeRef)
        let framesetter: CTFramesetterRef = CTFramesetterCreateWithAttributedString(currentText)
        let framePath: CGMutablePathRef = CGPathCreateMutable()
        CGPathAddRect(framePath, nil, frameRect)

        // Get the frame that will do the rendering
        let currentRange: CFRange = CFRangeMake(0, 0)
        let frameRef: CTFrameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, nil)

        // Get the graphics context
        let currentContext = UIGraphicsGetCurrentContext()

        // Put the text matrix into a known state. This ensures
        // that no old scaling factors are left in place.
        CGContextSetTextMatrix(currentContext, CGAffineTransformIdentity)

        // Core Text draws from the bottom-left corner up, so flip
        // the current transform prior to drawing.
        let offset: CGFloat = (frameRect.origin.y * 2) + frameRect.size.height
        CGContextTranslateCTM(currentContext, 0, offset)
        CGContextScaleCTM(currentContext, 1.0, -1.0)

        // Draw the frame.
        CTFrameDraw(frameRef, currentContext!)

        // Reset the transform
        CGContextScaleCTM(currentContext, 1.0, -1.0)
        CGContextTranslateCTM(currentContext, 0, -offset)
    }

    private enum TextAttribute {
        case TitleInfo
        case TitleLabel
        case TableRowHeader
        case TableRowText
        case CardDetailText

        func getAttributesWithColor(color: UIColor, andAlignment alignments: NSTextAlignment...) -> [[String: AnyObject]] {
            var attribs: [[String: AnyObject]] = []
            switch (self) {
                case .TitleInfo:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 16.0))
                    }
                case .TitleLabel:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 10.0))
                    }
                case .TableRowHeader:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 12.0))
                    }
                case .TableRowText:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 10.0))
                    }
                case .CardDetailText:
                    for alignment in alignments {
                        attribs.append(getTextAttributes(alignment, color: color, size: 8.0))
                }
            }
            return attribs
        }

        private func getTextAttributes(justification : NSTextAlignment, color: UIColor, size: CGFloat) -> [String : AnyObject] {
            let font = UIFont(name: fontName, size: size)
            let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            textStyle.alignment = justification
            let textColor = color
            return [
                NSFontAttributeName : font!,
                NSForegroundColorAttributeName: textColor,
                NSParagraphStyleAttributeName: textStyle
            ]
        }
    }

    private enum TableCellType {
        case Header
        case Expense
        case CostSummary
    }
}
