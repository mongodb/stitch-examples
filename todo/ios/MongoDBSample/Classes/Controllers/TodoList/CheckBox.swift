//
//  CheckBox.swift
//  MongoDBSample
//
//

import UIKit

@IBDesignable class CheckBox: UIControl {
    
    private struct Consts {
        static let defaultTintColor = UIColor(red: 0.23, green: 0.82, blue: 0.86, alpha: 1.0)
    }
    
    internal let shapeLayer = CAShapeLayer()
    internal let markLayer = CAShapeLayer()
    
    @IBInspectable public var checked: Bool = false {
        
        didSet {
            updateLayout()
        }
    }
    
    @IBInspectable public var color: UIColor = Consts.defaultTintColor {
        didSet {
            updateLayout()
        }
    }
    
    @IBInspectable public var shapeLineWidth: CGFloat = 2.0 {
        didSet {
            updateLayout()
        }
    }
    
    @IBInspectable public var markLineWidth: CGFloat = 2.0 {
        didSet {
            updateLayout()
        }
    }
    
    var shapePath: UIBezierPath {
        let radius = bounds.size.width / 2
        return UIBezierPath.init(arcCenter: CGPoint.init(x: radius, y: radius), radius: radius, startAngle: CGFloat.pi / 4.0, endAngle: CGFloat(2 * CGFloat.pi - (CGFloat.pi / 4.0)), clockwise: true)
    }
    
    var markPath: UIBezierPath {
        let path = UIBezierPath()
        
        let width = bounds.size.width * 0.5
        let pointA = CGPoint(x: width - bounds.size.width * 0.17, y: width + bounds.size.width * 0.02)
        let pointB = CGPoint(x: width - bounds.size.width * 0.004, y: width + bounds.size.width * 0.133)
        let pointC = CGPoint(x: width + bounds.size.width * 0.24, y: width - bounds.size.width * 0.137)
        path.move(to: pointA)
        path.addLine(to: pointB)
        path.addLine(to: pointC)
        
        return path
    }
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        updateLayout()
        layer.addSublayer(shapeLayer)
        layer.addSublayer(markLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateLayout()
    }
    //MARK: - Layout
    
    func updateLayout() {
        
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = checked ? color.cgColor : UIColor.clear.cgColor
        markLayer.strokeColor = checked ? UIColor.white.cgColor : UIColor.clear.cgColor
        markLayer.fillColor = UIColor.clear.cgColor
        
        shapeLayer.frame = bounds
        shapeLayer.lineWidth = shapeLineWidth
        shapeLayer.path = shapePath.cgPath
        
        markLayer.frame = bounds
        markLayer.lineWidth = markLineWidth
        markLayer.path = markPath.cgPath
    }
    
    //MARK: - IB
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()        
        commonInit()
    }
}
