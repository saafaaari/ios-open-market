//
//  OpenMarket - MainViewController.swift
//  Created by yagom. 
//  Copyright dudu, safari All rights reserved.
// 

import UIKit

private enum Section {
    case main
}

private enum Constant {
    static let requestItemCount = 20
}

final class MainViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Product>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Product>
    
    private var mainView: MainView?
    private var dataSource: DataSource?
    private var snapshot: Snapshot?
    
    private var pageNumber = 1
    
    private var networkManager = NetworkManager<ProductList>(imageCache: CacheManager())
    
    private lazy var segmentControl: CellSegmentControl = {
        let segmentControl = CellSegmentControl(items: ["LIST", "GRID"])
        segmentControl.addTarget(self, action: #selector(segmentValueDidChanged(segmentedControl:)), for: .valueChanged)
        return segmentControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureNavigationBar()
        configureRefreshControl()
        requestData(pageNumber: pageNumber)
    }
    
    override func loadView() {
        super.loadView()
        mainView = MainView(frame: view.bounds)
        view = mainView
    }
    
    private func configureView() {
        mainView?.backgroundColor = .systemBackground
        configureCollectionView()
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidTapped))
        navigationItem.titleView = segmentControl
    }
    
    private func configureCollectionView() {
        mainView?.collectionView.register(ProductGridCell.self, forCellWithReuseIdentifier: ProductGridCell.identifier)
        mainView?.collectionView.register(ProductListCell.self, forCellWithReuseIdentifier: ProductListCell.identifier)
        mainView?.collectionView.prefetchDataSource = self
        dataSource = makeDataSource()
        snapshot = makeSnapshot()
    }
    
    private func configureRefreshControl() {
        mainView?.collectionView.refreshControl = UIRefreshControl()
        mainView?.collectionView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
}

// MARK: - Action Method

extension MainViewController {
    @objc private func addButtonDidTapped() {}
    
    @objc private func segmentValueDidChanged(segmentedControl: UISegmentedControl) {
        mainView?.changeLayout(index: segmentedControl.selectedSegmentIndex)
        mainView?.collectionView.reloadData()
    }
    
    @objc private func handleRefreshControl() {
        pageNumber = 1
        snapshot = makeSnapshot()

        networkManager.clearCache()
        requestData(pageNumber: pageNumber)
    }
}

// MARK: - NetWork Method

extension MainViewController {
    private func requestData(pageNumber: Int) {
        let endPoint = EndPoint.requestList(page: pageNumber, itemsPerPage: Constant.requestItemCount, httpMethod: .get)
        
        networkManager.request(endPoint: endPoint) { [weak self] result in
            switch result {
            case .success(let data):
                guard let result = data.products else { return }
                
                self?.applySnapshot(products: result)
                
                DispatchQueue.main.async {
                    self?.mainView?.indicatorView.stop()
                    self?.mainView?.collectionView.refreshControl?.stop()
                }
            case .failure(_):
                break
            }
        }
    }
}

//MARK: - CollectionView DataSource

extension MainViewController {
    private func makeDataSource() -> DataSource? {
        
        guard let mainView = mainView else { return nil }
        
        let dataSource = DataSource(collectionView: mainView.collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            
            guard let self = self else { return nil }
            
            guard let layout = ProductCollectionViewLayoutType(rawValue: self.segmentControl.selectedSegmentIndex) else { return nil }
            let cellType = layout.cellType
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.identifier, for: indexPath) as? ProductCell else { return cellType.init() }
            
            cell.configure(data: itemIdentifier)
            self.networkManager.downloadImage(urlString: itemIdentifier.thumbnail) { result in
                switch result {
                case .success(let image):
                    DispatchQueue.main.async {
                        guard collectionView.indexPath(for: cell) == indexPath else { return }
                        cell.setImage(with: image)
                    }
                case .failure(_):
                    break
                }
            }
            
            return cell
        }
        
        return dataSource
    }
     
    private func makeSnapshot() -> Snapshot? {
        var snapshot = dataSource?.snapshot()
        snapshot?.deleteAllItems()
        snapshot?.appendSections([.main])
        
        return snapshot
    }
    
    private func applySnapshot(products: [Product]) {
        DispatchQueue.main.async { [self] in
            snapshot?.appendItems(products)
            
            guard let snapshot = snapshot else { return }
            
            dataSource?.apply(snapshot, animatingDifferences: false)
        }
    }
}

//MARK: - CollectionView DataSourcePrefetching

extension MainViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        prefetchData(indexPaths)
    }
    
    private func prefetchData(_ indexPaths: [IndexPath]) {
        guard let indexPath = indexPaths.last else { return }
        
        let section = indexPath.row / Constant.requestItemCount
        
        if section + 1 == pageNumber {
            pageNumber += 1
            requestData(pageNumber: pageNumber)
        }
    }
}
