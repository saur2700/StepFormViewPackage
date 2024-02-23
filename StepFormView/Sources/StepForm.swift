//
//  File.swift
//  
//
//  Created by Saurav Kumar on 23/02/24.
//

import UIKit

protocol StepFormViewDataSource: AnyObject {
    func numberOfSteps() -> Int
    func stepFormView(collapsedViewFor index: Int) -> UIView?
    func stepFormView(expandedViewFor index: Int) -> UIView?
}

protocol StepFormViewDelegate: AnyObject {
    func stepFormView(didMoveTo index: Int)
    func stepFormView(willMoveTo index: Int)
}

final class StepFormView: UIView {
    
    let stackView: UIStackView = {
        let stackView: UIStackView = .init()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    weak var dataSource: StepFormViewDataSource? {
        didSet {
            reset()
        }
    }
    
    private let animationDuration: CGFloat = 0.5
    
    weak var delegate: StepFormViewDelegate? {
        didSet {
            guard let currentIndex else {
                return
            }
            delegate?.stepFormView(didMoveTo: currentIndex)
        }
    }
    
    private var currentIndex: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension StepFormView {
    
    func commonInit() {
        setupHierarchy()
        setupConstraints()
    }
    
    func setupHierarchy() {
        self.addSubview(stackView)
    }
    
    func setupConstraints() {
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor).isActive = true
    }
}

private extension StepFormView {
    func reset() {
        if let numberOfRows = dataSource?.numberOfSteps(),
           numberOfRows > .zero
        {
            currentIndex = 0
            setupDataSource()
        } else {
            currentIndex = nil
        }
    }
    
    func setupDataSource() {
        guard let expandedView = dataSource?.stepFormView(expandedViewFor: 0) else {
            currentIndex = nil
            return
        }
        self.delegate?.stepFormView(willMoveTo: 0)
        self.delegate?.stepFormView(didMoveTo: 0)
        self.stackView.addArrangedSubview(expandedView)
    }
}

extension StepFormView {
    @discardableResult
    func next() -> Bool {
        guard let currentIndex else {
            return false
        }
        let nextIndex = currentIndex+1
        guard nextIndex < (dataSource?.numberOfSteps() ?? 0) else {
            return false
        }
        
        guard let collapsedView = dataSource?.stepFormView(collapsedViewFor: currentIndex) else {
            return false
        }
        
        guard let expandedView = dataSource?.stepFormView(expandedViewFor: nextIndex) else {
            return false
        }
        
        guard let stackLastSubView = stackView.arrangedSubviews.last else {
            return false
        }
        
        stackView.removeArrangedSubview(stackLastSubView)
        stackLastSubView.removeFromSuperview()
        
        stackView.addArrangedSubview(collapsedView)
        stackView.addArrangedSubview(expandedView)
        expandedView.alpha = 0.5
        expandedView.transform = CGAffineTransform(translationX: 0, y: 300)
        self.delegate?.stepFormView(willMoveTo: nextIndex)
        UIView.animate(withDuration: animationDuration) {
            expandedView.alpha = 1
            expandedView.transform = .identity
        } completion: { _ in
            self.currentIndex = nextIndex
            self.delegate?.stepFormView(didMoveTo: nextIndex)
        }
        return true
    }
    
    @discardableResult
    func previous() -> Bool {
        guard let currentIndex else {
            return false
        }
        guard currentIndex > 0 else {
            return false
        }
        let previousIndex = currentIndex-1
        guard let expandedView = dataSource?.stepFormView(expandedViewFor: previousIndex) else {
            return false
        }
        
        let count = stackView.arrangedSubviews.count
        guard count > 1,
              let stackLastSubView = stackView.arrangedSubviews.last else {
            return false
        }
        let lastCollapsedIndex = count-2
        let stackLastCollapsedView = stackView.arrangedSubviews[lastCollapsedIndex]
        
        stackLastSubView.widthAnchor.constraint(equalTo: self.stackView.widthAnchor).isActive = true
        let frame = stackLastSubView.frame
        self.stackView.removeArrangedSubview(stackLastSubView)
        
        stackView.removeArrangedSubview(stackLastCollapsedView)
        stackLastCollapsedView.removeFromSuperview()
        stackView.insertArrangedSubview(expandedView, at: lastCollapsedIndex)
        expandedView.alpha = 0
        stackView.bringSubviewToFront(stackLastSubView)
        self.stackView.layoutIfNeeded()
        stackLastSubView.frame = frame
        self.delegate?.stepFormView(willMoveTo: previousIndex)
        UIView.animate(withDuration: animationDuration) {
            expandedView.alpha = 1
            stackLastSubView.transform = CGAffineTransform(translationX: 0, y: 400)
            stackLastSubView.alpha = 0
        } completion: { _ in
            stackLastSubView.removeFromSuperview()
            self.currentIndex = previousIndex
            self.delegate?.stepFormView(didMoveTo: previousIndex)
        }
        return true
    }
    
    @discardableResult
    func moveToIndex(index: Int) -> Bool {
        guard index >= 0, index < self.dataSource?.numberOfSteps() ?? 0 else {
            return false
        }
        guard let currentIndex else {
            return false
        }
        guard currentIndex < index else {
            return false
        }
        
        guard let expandedView = dataSource?.stepFormView(expandedViewFor: index) else {
            return false
        }
        
        stackView.arrangedSubviews.enumerated()
            .forEach { (offset, subView) in
                if offset >= index {
                    stackView.removeArrangedSubview(subView)
                    subView.removeFromSuperview()
                }
            }
        stackView.addArrangedSubview(expandedView)
        self.currentIndex = index
        return true
    }
}
