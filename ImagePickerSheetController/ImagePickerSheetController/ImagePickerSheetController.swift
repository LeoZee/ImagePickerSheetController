//
//  ImagePickerController.swift
//  ImagePickerSheet
//
//  Created by Laurin Brandner on 24/05/15.
//  Copyright (c) 2015 Laurin Brandner. All rights reserved.
//

import Foundation
import Photos

private let previewCollectionViewInset: CGFloat = 5

/// The media type an instance of ImagePickerSheetController can display
public enum ImagePickerMediaType : Int {
    case image
    case video
    case imageAndVideo
    case none
}

@available(iOS 8.0, *)
public class ImagePickerSheetController: UIViewController {
    
    var sheetCollectionView: UICollectionView {
        return sheetController.sheetCollectionView
    }

    private lazy var sheetController: SheetController = {
        let controller = SheetController(previewCollectionView: self.previewCollectionView)
        controller.displayPreview = self.mediaType != .none;
        controller.actionHandlingCallback = { [weak self] in
			self?.dismiss(animated: true, completion: nil)
        }
        
        return controller
    }()
    
    private(set) lazy var previewCollectionView: PreviewCollectionView = {
        let collectionView = PreviewCollectionView()
        collectionView.accessibilityIdentifier = "ImagePickerSheetPreview"
		collectionView.backgroundColor = .clear
        collectionView.allowsMultipleSelection = true
		collectionView.imagePreviewLayout.sectionInset = UIEdgeInsets(top: previewCollectionViewInset, left: previewCollectionViewInset, bottom: previewCollectionViewInset, right: previewCollectionViewInset)
        collectionView.imagePreviewLayout.showsSupplementaryViews = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
		collectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(PreviewCollectionViewCell.self))
		collectionView.register(PreviewSupplementaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(PreviewSupplementaryView.self))
        
        return collectionView
    }()
    
    private var supplementaryViews = [Int: PreviewSupplementaryView]()
    
    lazy var backgroundView: UIView = {
        
        let view = UIView()
        view.accessibilityIdentifier = "ImagePickerSheetBackground"
        
        if !self.isPresentedAsPopover {
            view.backgroundColor = UIColor(white: 0.0, alpha: 0.3961)
        }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ImagePickerSheetController.cancel)))
        
        return view
    }()
    
    /// All the actions. The first action is shown at the top.
    public var actions: [ImagePickerAction] {
        return sheetController.actions
    }
    
    private var selectedAssets:[PHAsset] = [] {
        didSet {
            sheetController.numberOfSelectedImages = selectedAssets.count
        }
    }
    private var assets:[PHAsset] = []
    
    private lazy var requestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
		options.deliveryMode = .opportunistic
		options.resizeMode = .fast
        
        return options
    }()
    
    private lazy var imageManager: PHCachingImageManager? = {
    
        if self.mediaType == .none {
            return nil
        }
        
        return PHCachingImageManager();
    }()
    
    private let minimumPreviewHeight: CGFloat = 129
    private var maximumPreviewHeight: CGFloat = 129
    
    private var previewCheckmarkInset: CGFloat {
        guard #available(iOS 9, *) else {
            return 3.5
        }
        
        return 12.5
    }
    
    override public var modalPresentationStyle:UIModalPresentationStyle {
        didSet {
			if modalPresentationStyle == .popover {
				backgroundView.backgroundColor = .clear
            } else {
                backgroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.3961)
            }
        }
    }
    
    private var isPresentedAsPopover:Bool {
        
        let style = self.popoverPresentationController?.presentationStyle
		return style == .popover && modalPresentationStyle == .popover
    }
    
    // MARK: - Public accessable variables
	
	/// Set larger bottom margin for Iphone X types
	public var isIphoneXtype = true
    
    /// Maximum number of images to display (larger amounts can slow down the result!
    public var imageLimit = 50
    
    /// Specify the preferred status bar style
    public var statusBarStyle:UIStatusBarStyle?
    
    /// If set to true, after taping on preview image it enlarges
    public var enableEnlargedPreviews: Bool = true
    
    /// Maximum selection of images.
    public var maximumSelection: Int?
    
    /// The selected image assets
    public var selectedImageAssets: [PHAsset] {
        return selectedAssets
    }
    
    /// The media type of the displayed assets
    public let mediaType: ImagePickerMediaType
    
    /// Whether the image preview has been elarged. This is the case when at least once
    /// image has been selected.
    public private(set) var enlargedPreviews = false
    
    // MARK: - Initialization
    
    public init(mediaType: ImagePickerMediaType, selectedAssets:[PHAsset] = []) {
        
        self.mediaType = mediaType
        self.selectedAssets = selectedAssets
        
        super.init(nibName: nil, bundle: nil)
        initialize()
        
        self.sheetController.numberOfSelectedImages = selectedAssets.count
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        self.mediaType = .imageAndVideo
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        
		modalPresentationStyle = .custom
        transitioningDelegate = self
        
		NotificationCenter.default.addObserver(self, selector: #selector(ImagePickerSheetController.cancel), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        
		NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Lifecycle
    override public func loadView() {
        
        super.loadView()
        self.view.backgroundColor = .clear
        view.addSubview(backgroundView)
        view.addSubview(sheetCollectionView)
    }
    
	public override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if mediaType == .none {
//            previewCollectionView.removeFromSuperview()
            
        } else {
            preferredContentSize = CGSize(width: 400, height: view.frame.height)
            
			if PHPhotoLibrary.authorizationStatus() == .authorized {
                prepareAssets()
            }
        }
    }
    
	public override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
		if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization() { status in
				if status == .authorized {
					DispatchQueue.main.async {
                        self.prepareAssets()
                        self.previewCollectionView.reloadData()
                        self.sheetCollectionView.reloadData()
                        self.view.setNeedsLayout()
                        
                        // Explicitely disable animations so it wouldn't animate either
                        // if it was in a popover
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        self.view.layoutIfNeeded()
                        CATransaction.commit()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Adds an new action.
    /// If the passed action is of type Cancel, any pre-existing Cancel actions will be removed.
    /// Always arranges the actions so that the Cancel action appears at the bottom.
    public func addAction(_ action: ImagePickerAction) {
        
		sheetController.addAction(action: action)
        view.setNeedsLayout()
    }
    
    @objc private func cancel() {
        
        sheetController.handleCancelAction()
    }
    
    // MARK: - Images
    
    private func sizeForAsset(asset: PHAsset, scale: CGFloat = 1) -> CGSize {
        
        let proportion = CGFloat(asset.pixelWidth)/CGFloat(asset.pixelHeight)
        
        let imageHeight = maximumPreviewHeight - 2 * previewCollectionViewInset
        let imageWidth = floor(proportion * imageHeight)
        
        return CGSize(width: imageWidth * scale, height: imageHeight * scale)
    }
    
    private func prepareAssets() {
        
        if mediaType == .none {
            return
        }
        
        fetchAssets()
        reloadMaximumPreviewHeight()
        reloadCurrentPreviewHeight(invalidateLayout: false)
        
        // Filter out the assets that are too thin. This can't be done before because
        // we don't know how tall the images should be
        let minImageWidth = 2 * previewCheckmarkInset + (PreviewSupplementaryView.checkmarkImage?.size.width ?? 0)
        assets = assets.filter { asset in
			let size = sizeForAsset(asset: asset)
            return size.width >= minImageWidth
        }
    }
    
    private func fetchAssets() {
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        switch mediaType {
        case .image:
			options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        case .video:
			options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        case .imageAndVideo:
			options.predicate = NSPredicate(format: "mediaType = %d OR mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        case .none: return;
            
        }
        
        if #available(iOS 9, *) {
            options.fetchLimit = imageLimit
        }
        
		let result = PHAsset.fetchAssets(with: options)
        let amount = min(result.count, imageLimit)
        
		self.assets = result.objects(at: NSIndexSet(indexesIn: NSRange(location: 0, length: amount)) as IndexSet)
        sheetController.reloadActionItems()
        
        for asset in selectedAssets {
            if let index = assets.firstIndex(of: asset) {
				previewCollectionView.selectItem(at: IndexPath(row: 0, section: index), animated: false, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
	private func requestImageForAsset(asset: PHAsset, completion: @escaping (_ image: UIImage?, _ requestId:PHImageRequestID?) -> ()) -> PHImageRequestID {
        
        if let manager = self.imageManager  {
			let targetSize = sizeForAsset(asset: asset, scale: UIScreen.main.scale)
			requestOptions.isSynchronous = false
            
            // Workaround because PHImageManager.requestImageForAsset doesn't work for burst images
            if asset.representsBurst {
				return manager.requestImageData(for: asset, options: requestOptions) { data, _, _, dict in
                    let image = data.flatMap { UIImage(data: $0) }
                    let requestId = dict?[PHImageResultRequestIDKey] as? NSNumber
					completion(image, requestId?.int32Value)
                }
            }
            else {
				return manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, dict in
                    let requestId = dict?[PHImageResultRequestIDKey] as? NSNumber
					completion(image, requestId?.int32Value)
                }
            }
        }
        
        return 0
    }
    
    private func prefetchImagesForAsset(asset: PHAsset) {
        if let manager = self.imageManager {
			let targetSize = sizeForAsset(asset: asset, scale: UIScreen.main.scale)
			manager.startCachingImages(for: [asset], targetSize: targetSize, contentMode: .aspectFill, options: requestOptions)
        }
    }
    
    // MARK: - Layout
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let window = UIApplication.shared.windows.first {
            
            let windowFrame = window.bounds
			let offset = view.convert(view.bounds, to: nil)
            backgroundView.frame = CGRect(x: -offset.origin.x, y: -offset.origin.y, width: windowFrame.width, height: windowFrame.height)
            
        } else {
            backgroundView.frame = view.bounds
        }
        
        reloadMaximumPreviewHeight()
        reloadCurrentPreviewHeight(invalidateLayout: true)
        
        var sheetHeight = sheetController.preferredSheetHeight
        let sheetSize = CGSize(width: view.bounds.width, height: sheetHeight)
		
		if isIphoneXtype {
			sheetHeight += 20
		}
		
        // This particular order is necessary so that the sheet is layed out
        // correctly with and without an enclosing popover
        preferredContentSize = sheetSize
        sheetCollectionView.frame = CGRect(origin: CGPoint(x: view.bounds.minX, y: view.bounds.maxY-sheetHeight), size: sheetSize)
    }
    
    private func reloadCurrentPreviewHeight(invalidateLayout invalidate: Bool) {
        if assets.count <= 0 {
			sheetController.setPreviewHeight(height: 0, invalidateLayout: invalidate)
        }
        else if assets.count > 0 && enlargedPreviews {
			sheetController.setPreviewHeight(height: maximumPreviewHeight, invalidateLayout: invalidate)
        }
        else {
			sheetController.setPreviewHeight(height: minimumPreviewHeight, invalidateLayout: invalidate)
        }
    }
    
    private func reloadMaximumPreviewHeight() {
        let maxHeight: CGFloat = 400
        let maxImageWidth = sheetController.preferredSheetWidth - 2 * previewCollectionViewInset
        
        let assetRatios = assets.map { CGSize(width: max($0.pixelHeight, $0.pixelWidth), height: min($0.pixelHeight, $0.pixelWidth)) }
            .map { $0.height / $0.width }
        
        var assetHeights = assetRatios.map { $0 * maxImageWidth }
		assetHeights = assetHeights.filter{ $0 < maxImageWidth && $0 < maxHeight } // Make sure the preview isn't too high eg for squares
		assetHeights.sort()
        let assetHeight = ceil(assetHeights.first ?? 0)
        
        // Just a sanity check, to make sure this doesn't exceed 400 points
        let scaledHeight = max(min(assetHeight, maxHeight), 200)
        maximumPreviewHeight = scaledHeight + 2 * previewCollectionViewInset
    }
    
    // MARK: -
    
	func enlargePreviewsByCenteringToIndexPath(indexPath: NSIndexPath?, completion: ((Bool) -> ())?) {
        enlargedPreviews = enableEnlargedPreviews
        
        previewCollectionView.imagePreviewLayout.invalidationCenteredIndexPath = indexPath
        reloadCurrentPreviewHeight(invalidateLayout: false)
        
        view.setNeedsLayout()
        
		let animationDuration: TimeInterval
        if #available(iOS 9, *) {
            animationDuration = 0.2
        }
        else {
            animationDuration = 0.3
        }
		
		UIView.animate(withDuration: animationDuration, animations: {
			self.sheetCollectionView.reloadSections(NSIndexSet(index: 0) as IndexSet)
            self.view.layoutIfNeeded()
            }, completion: completion)
    }
	
	public override var preferredStatusBarStyle: UIStatusBarStyle {
		if let statusBarStyle = statusBarStyle {
			return statusBarStyle
		}
		return super.preferredStatusBarStyle
	}
	
}

// MARK: - UICollectionViewDataSource

extension ImagePickerSheetController: UICollectionViewDataSource {
	
	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		return self.mediaType == .none ? 0 : assets.count
	}
    
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(PreviewCollectionViewCell.self), for: indexPath as IndexPath) as! PreviewCollectionViewCell
        
        if let imageManager = self.imageManager {
            let asset = assets[indexPath.section]
            if let id = cell.requestId {
                imageManager.cancelImageRequest(id)
                cell.requestId = nil
            }
			cell.videoIndicatorView.isHidden = asset.mediaType != .video
            
			cell.requestId = requestImageForAsset(asset: asset) { image, requestId in
                if requestId == cell.requestId || cell.requestId == nil {
                    cell.imageView.image = image
                }
            }
            
			cell.isSelected = selectedAssets.contains(asset)
        }
        
        return cell
    }
    
	public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath:
		IndexPath) -> UICollectionReusableView {
            
		let asset = assets[indexPath.section]
		let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(PreviewSupplementaryView.self), for: indexPath as IndexPath) as! PreviewSupplementaryView
		view.isUserInteractionEnabled = false
		view.buttonInset = UIEdgeInsets(top: 0.0, left: previewCheckmarkInset, bottom: previewCheckmarkInset, right: 0.0)
            
		supplementaryViews[indexPath.section] = view
		view.selected = selectedAssets.contains(asset)
            
		return view
    }
}

// MARK: - UICollectionViewDelegate

extension ImagePickerSheetController: UICollectionViewDelegate {
	
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
        if let maximumSelection = maximumSelection {
			if selectedAssets.count >= maximumSelection, let previousAsset = selectedAssets.first, let previousItemIndex =
				assets.firstIndex(of: previousAsset) {
                
				let previousItemIndexPath = NSIndexPath(item: 0, section: previousItemIndex)
                
                supplementaryViews[previousItemIndex]?.selected = false
				selectedAssets.remove(element: previousAsset)
				collectionView.deselectItem(at: previousItemIndexPath as IndexPath, animated: true)
            }
        }
        
        let asset = assets[indexPath.section]
        // Just to make sure the image is only selected once
        if !selectedAssets.contains(asset) {
            selectedAssets.append(asset)
        }
        
        if !enlargedPreviews {
            //            enlargePreviewsByCenteringToIndexPath(indexPath) { _ in
            self.sheetController.reloadActionItems()
            self.previewCollectionView.imagePreviewLayout.showsSupplementaryViews = true
            //            }
        }
        else {
            // scrollToItemAtIndexPath doesn't work reliably
			if let cell = collectionView.cellForItem(at: indexPath) {
				
                var contentOffset = CGPoint(x: cell.frame.midX - collectionView.frame.width / 2.0, y: 0.0)
                contentOffset.x = max(contentOffset.x, -collectionView.contentInset.left)
                contentOffset.x = min(contentOffset.x, collectionView.contentSize.width - collectionView.frame.width + collectionView.contentInset.right)
                
                collectionView.setContentOffset(contentOffset, animated: true)
            }
            
            sheetController.reloadActionItems()
        }
        
        supplementaryViews[indexPath.section]?.selected = true
    }
    
	public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
		if let asset = assets.objectAtIndex(index: indexPath.section) {
			selectedAssets.remove(element: asset)
            sheetController.reloadActionItems()
        }
        
        supplementaryViews[indexPath.section]?.selected = false
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ImagePickerSheetController: UICollectionViewDelegateFlowLayout {
    
	public func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let asset = assets[indexPath.section]
		let size = sizeForAsset(asset: asset)
        
        // Scale down to the current preview height, sizeForAsset returns the original size
        let currentImagePreviewHeight = sheetController.previewHeight - 2 * previewCollectionViewInset
        let scale = currentImagePreviewHeight / size.height
        
        return CGSize(width: size.width * scale, height: currentImagePreviewHeight)
    }
    
	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let checkmarkWidth = PreviewSupplementaryView.checkmarkImage?.size.width ?? 0
		return CGSize(width: checkmarkWidth + 2 * previewCheckmarkInset, height: sheetController.previewHeight - 2 * previewCollectionViewInset)
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension ImagePickerSheetController: UIViewControllerTransitioningDelegate {
    
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimationController(imagePickerSheetController: self, presenting: true)
    }
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimationController(imagePickerSheetController: self, presenting: false)
    }
    
}

private extension Array where Element : Equatable {
    
    func objectAtIndex(index:Int) -> Element? {
        
        if self.count > index {
            return self[index]
        }
        return nil
    }
    
    mutating func remove(element:Element) {
        if let index = self.firstIndex(of: element) {
			self.remove(at: index)
        }
    }
}
