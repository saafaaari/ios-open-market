//
//  ProductViewController.swift
//  OpenMarket
//
//  Created by dudu, safari on 2022/05/25.
//

import UIKit

// MARK: - Abstract Class

class ProductViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, UIImage>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, UIImage>
    
    let networkManager = NetworkManager()
    
    var mainView: ProdctView?
    var dataSource: DataSource?
    var snapshot: Snapshot?
    
    override func loadView() {
        super.loadView()
        mainView = ProdctView(frame: view.bounds)
        view = mainView
    }
    
    deinit {
        removeNotification()
    }
    
    // MARK: - Configure Method
    
    func configureView() {
        configureCollectionView()
        configureNavigationBar()
        configureTextField()
        configureTextView()
    }
    
    func configureCollectionView() {
        mainView?.collectionView.register(ProductImageCell.self, forCellWithReuseIdentifier: ProductImageCell.identifier)
        dataSource = makeDataSource()
        snapshot = makeSnapsnot()
    }

    
    func configureTextField() {
        mainView?.productNameTextField.delegate = self
        mainView?.productCostTextField.delegate = self
        mainView?.productDiscountCostTextField.delegate = self
        mainView?.productStockTextField.delegate = self
    }
    
    func configureTextView() {
        mainView?.productDescriptionTextView.delegate = self
    }
    
    func configureNavigationBar() {
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonDidTapped))
        let rightBarButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonDidTapped))
        
        navigationItem.leftBarButtonItem = leftBarButton
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    @objc func cancelButtonDidTapped() {
        // empty
    }
    
    @objc func doneButtonDidTapped() {
        // empty
    }
    
    // MARK: - Notification
    
    func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ sender: Notification) {
        if mainView?.productDescriptionTextView.isFirstResponder == true {
            mainView?.frame.origin.y = -mainView!.productDescriptionTextView.frame.origin.y
        }
    }
    
    @objc private func keyboardWillHide(_ sender: Notification) {
        mainView?.frame.origin.y = 0
    }
    
    func removeNotification() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - CollectionView DataSource
    
    func makeDataSource() -> DataSource? {
        return nil
    }
    
    func makeSnapsnot() -> Snapshot? {
        var snapshot = dataSource?.snapshot()
        snapshot?.deleteAllItems()
        snapshot?.appendSections([.main])
        return snapshot
    }
    
    func applySnapshot(images: [UIImage]) {
        DispatchQueue.main.async { [self] in
            snapshot?.appendItems(images)
            guard let snapshot = snapshot else { return }
            
            dataSource?.apply(snapshot, animatingDifferences: false)
        }
    }
}

// MARK: - UITextField Delegate

extension ProductViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = textField.text ?? ""
        let finalText = makeFinalText(currentString, shouldChangeCharactersIn: range, replacementString: string)
        if finalText.count == .zero { return true }
        
        switch textField {
        case mainView?.productNameTextField:
            return (0...100).contains(finalText.count)
        case mainView?.productCostTextField:
            mainView?.productDiscountCostTextField.text = ""
            return Double(finalText) == nil ? false : true
        case mainView?.productDiscountCostTextField:
            guard let discountCost = Double(finalText),
                  let costString = mainView?.productCostTextField.text,
                  let cost = Double(costString) else { return false }
    
            return (0...cost).contains(discountCost)
        case mainView?.productStockTextField:
            return Int(finalText) == nil ? false : true
        default:
            return false
        }
    }
    
    private func makeFinalText(_ currentString: String, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> String {
        let currentString = currentString as NSString
        let nextString = currentString.replacingCharacters(in: range, with: string)
        
        return nextString
    }
}

// MARK: - UITextView Delegate

extension ProductViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentString = textView.text ?? ""
        let finalText = makeFinalText(currentString, shouldChangeCharactersIn: range, replacementString: text)
        return (0...1000).contains(finalText.count)
    }
}
