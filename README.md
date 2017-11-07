![Image Picker: Image picker for chat applications](https://user-images.githubusercontent.com/500145/31496739-deaafdc4-af5c-11e7-847c-03266262d990.png)

An easy to use drop-in framework providing user interface for taking pictures and videos and pick assets from Photo Library. User interface is designed to support `inputView` "keyboard-like" presentation for conversation user interfaces. Project is written in Swift4.

![Demo](https://user-images.githubusercontent.com/500145/31496397-766f626e-af5b-11e7-9d6f-c0c5dda93086.gif)

**Features:**
- [x] presentation designed for chat apps as well as regular view controllers
- [x] portrait and landscape modes
- [x] capturing assets (photos, live photos, videos)
- [x] saving captured assets to Photo Library
- [x] flipping camera to front/rear
- [x] turning on/off live photos
- [x] highly customisable layout and UI

**Features to add:**
- [x] support for iPhone X

**Requirements**
- iOS 10.1+
- Xcode 9+
- Swift 4

**Installation**
- [Carthage](https://github.com/Carthage/Carthage)
- manually

## Overview

A central object `ImagePickerController` manages user interactions and delivers the results of those interactions to a delegate object. The role and appearance of an image picker controller depend on the configuration you set up before presenting it.

Image Picker consists of 3 main functional parts:

1. **section of action items** - supports up to 2 action buttons, this section is optional and by default contains action item for camera and photos.
2. **section of camera item** - shows camera's video output and provides UI for user to take photos, videos, etc. This section is optinal and by default it's turned on.
3. **section of asset items** - shows thumbnails of assets found in Photo Library allowing user to select them. Section is mandatory and and can not be turned off.

To use an image picker controller, you must provide a delegate that conforms to `ImagePickerControllerDelegate` protocol. Use delegate to get informed when user takes a picture or selects an asset from library and configure custom action and asset collection view cells.

To use an image picker controller, perform these steps:

1. register permissions in your `info.plist` file (see Permissions section for more info.)
2. create new instance of ImagePickerController
3. optionally configure **appearance**, **layout**, **custom cells** and **capture mode**
4. present image picker's view controller

## Permissions

iOS requires you to register the following permission keys in info.plist:

- `NSPhotoLibraryUsageDescription` - for displaying photos and videos from device's Photo Library
- `NSCameraUsageDescription` - for taking pictures and capturing videos
- `NSMicrophoneUsageDescription` - for recording videos or live photos with an audio track

App asks for permissions automatically only when it's needed.

## Configuration

Various kind of configuration is supported. All configuration should be done **before** the view controller's view is first accessed.

- to configure what kind of media should be captured use `CaptureSettings`
- to configure general visual appearance use `Appearance` class
- to configure layout of action, camera and asset items use `LayoutConfiguration` class.
- to use your custom views for action, camera and asset items use `CellRegistrator` class
- don't forget to set your `delegate` and `dataSource` if needed
- to define a source of photos that should be available to pick up use view controller's `assetsFetchResultBlock` block

### Capture settings

Currently Image Picker supports capturing *photos*, *live photos* and *videos*.

To configure Image Picker to support desired media type use `CaptureSettings` struct. Use property `cameraMode` to specify what kind of output you are interested in. If you don't intend to support live photos at all, please use value `photo`, otherwise `photoAndLivePhoto`. If you wish to capture photos and videos use `photoAndVideo`. Capturing videos and live photos at the same time is not supported and you nor can't switch between presets after it's been configrued.

By default, all captured photos are not saved to Photo Library but rather provided to you by the delegate right away. However if you wish to save photos to photo library set `savesCapturedPhotosToPhotoLibrary` to *true*. Live photos and videos are saved to Photo Library automatically.

An example of configuration for taking photos and live photos and saving them to photo library:

```swift
let imagePicker = ImagePickerController()
imagePicker.captureSettings.cameraMode = .photoAndLivePhoto
imagePicker.captureSettings.savesCapturedPhotosToPhotoLibrary = true
```

Please refer to `CaptureSettings` public header for more information.

### Providing your own photos fetch result

By default Image Picker fetches from Photo Library 1000 photos and videos from smart album `smartAlbumUserLibrary` that should represent *Camera Roll* album. If you wish to provide your own fetch result please implement image picker controller's `assetsFetchResultBlock` block.

For example to fetch only live photos you can use following code snippet:

```swift
let imagePicker = ImagePickerController()
imagePicker.assetsFetchResultBlock = {
    guard let livePhotosCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumLivePhotos, options: nil).firstObject else {
        return nil //you can return nil if you did not find desired fetch result, default fetch result will be used.
    }
    return PHAsset.fetchAssets(in: livePhotosCollection, options: nil)
}
```
For more information how to configure fetch results please refer to [Photos framework documentation](https://developer.apple.com/documentation/photos).

### Styling using Appearance

Image picker view hierarchy contains of `UICollectionView` to show action, camera and asset items and an overlay view to show permissions status. When custom cells are provided via `CellRegistrator` it is your responsibility to do the styling as well styling custom overlay view for permissions status. However, few style attributes are supported such as background color. Please use custom appearance mechanism to achieve desired styling.

1. to style all image pickers globally use global appearance proxy object:
```swift
ImagePickerController.appearance().backgroundColor = UIColor.black
```

2. to style a particular instance of image picker use instances appearance proxy object:
```swift
let vc = ImagePickerController()
vc.appearance().backgroundColor = UIColor.black
```

For default styling attributes and more info please refer to public interface of `Appearance` class.

Please note that UIKit's appearance proxy is not currently supported.

### Defining layout using LayoutConfiguration

Image picker supports various kind of layouts and both vertical and horizontal scroll direction. Using `LayoutConfiguration` you can set layout that you need specifically to your app.

1. **Action Items** are always shown as first section and can contain up to 2 buttons. By default this section shows 2 items. Next example will show how to turn off second action item:
```swift
let imagePicker = ImagePickerController()
imagePicker.layoutConfiguration.showsSecondActionItem = false
```

2. **Camera Item** is always shown in a section after action items section. So if action item if off this section is shown as first. Camera item section is by default on, so if you wish to turn it off use following code:
```swift
let imagePicker = ImagePickerController()
imagePicker.layoutConfiguration.showsCameraItem = false
```
> Please note that if you turn off camera section, Image Picker will not ask user for camera permissions.

3. **Asset Items** are always shown regardless if there are any photos in the app. You can control how many asset items are in a col or a row (based on scroll direction). By default, there are 2 asset in a col or a row. To change this to 1 see next snippet:
```swift
let imagePicker = ImagePickerController()
imagePicker.layoutConfiguration.numberOfAssetItemsInRow = 1
```
> Please note that provided value must be greater than 0 otherwise an exception will be thrown.

4. **Other layout properties**
 - *interitemSpacing* - spacing between items when laying out the grid
 - *actionSectionSpacing* - spacing between action items section and camera item section
 - *cameraSectionSpacing* - spacing between camera section and asset items section


### Providing custom views

All views used by Image Picker can be provided by you to achieve highly customisable UI that fits your app the best. As mentioned earlier, whole UI consists of a collection view and an overlay view.

- **collection view** uses cells to display action, camera and asset items. By default Image Picker provides cells for you with standard features and UI. However, if you wish to use your own cells incorporating your own UI and features use `CellRegistrator`. It contains API to register both nibs and classes for each section type. For example to register custom cells for action items section use following code:
```swift
let imagePicker = ImagePickerController()
imagePicker.cellRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
```
Same principle is applied to registering custom camera and asset items. You can also set specific cells for each asset media types such photos and videos. For example to use specific cell for video  assets use:
```swift
let imagePicker = ImagePickerController()
imagePicker.cellRegistrator.register(cellClass: CustomVideoCell.self, forAssetItemOf: .video)
imagePicker.cellRegistrator.register(cellClass: CustomImageCell.self, forAssetItemOf: .image)
```
> *Note:* Please make sure that if you use custom cells you register cells for all media types (audio, video) otherwise Image Picker will throw an exception. Please don't forget that camera item cells **must** subclass CameraCollectionViewCell and asset items cells **must** conform to `ImagePickerAssetCell` protocol. You can also fine-tune your asset cells to a specific asset types such us live photos, panorama photos, etc. using the delegate. Please see our ExampleApp for implementation details.

- **overlay view** is shown over collection view in situations when app does not have access permissions to *Photos Library*. To support overlay view please implement a datasource conforming to `ImagePickerControllerDatasource` protocol. Possible implementation could look like this:
```swift
extension ViewController: ImagePickerControllerDataSource {
    func imagePicker(controller: ImagePickerController, viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView {
        let statusView = CustomPermissionStatusView(frame: .zero)
        //configure and return view based on authorization status
        return statusView
    }
}
```

### Implementing custom action cell

If you wish to use your own action item cells, please register your cell classes or nibs at `CellRegistrator`. After that implement corresponding `ImagePickerControllerDelegate` method to configure cell before it's displayed.

1. use layout configuration to set your number of action items desired
```swift
let imagePicker = ImagePickerController()
imagePicker.layoutConfiguration.showsFirstActionItem = true
imagePicker.layoutConfiguration.showsSecondActionItem = true
```

2. register your action cells on cell registrator, for example
```swift
imagePicker.registerCellClassForActionItems(IconWithTextCell.self)
```

3. configure cell by implementing delegate method, for example
```swift
func imagePicker(controller: ImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {
    switch cell {
    case let iconWithTextCell as IconWithTextCell:
        switch index {
        case 0:
            iconWithTextCell.titleLabel.text = "Camera"
            iconWithTextCell.imageView.image = #imageLiteral(resourceName: "ic-camera")
        case 1:
            iconWithTextCell.titleLabel.text = "Photo Library"
            iconWithTextCell.imageView.image = #imageLiteral(resourceName: "ic-photo")
        default: break
        }
    default:
        break
    }
}
```

4. handle actions by implementing delegate method
```swift
func imagePicker(controller: ImagePickerController, didSelectActionItemAt index: Int) {
    print("did select action \(index)")
}
```

### Implementing custom camera cell

Image picker provides a default camera cell that adapts to taking pictures, live photos or videos based on `captureSettings`.

If you wish to implement fancier features you must provide your own subclass of `CameraCollectionViewCell` or nib file with custom cell class subclassing it and implement dedicated methods.

> Note: Please note, that custom nib's cell class must inherit from `CameraCollectionViewCell` and must not specify any reuse identifer. Image Picker is handling reuse identifiers internally.

Supported features of whoose UI can be fully customized:
- [x] taking photos, live photos, recording videos, flipping camera
- [x] providing custom buttons (camera flipping, taking photos, recording videos)
- [x] updating Live Photo status
- [x] updating recording status
- [x] showing current access permissions to camera

To see an example of custom implementation that supports all mentioned features please see class `LivePhotoCameraCell` and `VideoCameraCell` of *Image Picker* source code..

### Implementing custom assets cell

Image picker provides a default assets cell that shows an image thumbnail, selected state, if asset is video it shows an icon and duration and if it's an live photo it shows an icon. If you wish to provide custom asset cell, that could show for example asset's media subtype (live photo, panorama, HDR, screenshot, streamed video, etc.) simply register your own asset cells on `CellRegistrator` that conforms to `ImagePickerAssetCell` and in implement image picker delegate's `func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset)` method. Possible example implementation could be:

1. register cell classes for each asset media type, for example
```swift
let imagePicker = ImagePickerController()
imagePicker.register(cellClass: CustomImageCell.self, forAssetItemOf: .image)
imagePicker.register(cellClass: CustomVideoCell.self, forAssetItemOf: .video)
```
> Please note, that `CellRegistrator` provides a method to register 1 cell or nib for any asset media type.

2. implement delegate method to configure your asset cells, for example
```swift
func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset) {
    switch cell {
        
    case let videoCell as CustomVideoCell:
        videoCell.label.text = ViewController.durationFormatter.string(from: asset.duration)
        
    case let imageCell as CustomImageCell:
        if asset.mediaSubtypes.contains(.photoLive) {
            imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-live")
        }
        else if asset.mediaSubtypes.contains(.photoPanorama) {
            imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-pano")
        }
        else if #available(iOS 10.2, *), asset.mediaSubtypes.contains(.photoDepthEffect) {
            imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-depth")
        }
    default:
        break
    }
}
```

To see an example of custom implementation that supports all mentioned features please see class `VideoAssetCell` and `AssetCell` of *Image Picker* source code.

## Presentation

If you wish to present Image Picker in default set up, you don't need to do any special configuration, simple create new instance and present a view controller:

```swift
let imagePicker = ImagePickerController()
navigationController.present(imagePicker, animated: true, completion: nil)
```

However, most of the time you will want to do custom configuration so please do all the configuration before the view controller's view is loaded (`viewDidLoad()` method is called).

```swift
let imagePicker = ImagePickerController()
imagePicker.cellRegistrator ...
imagePicker.layoutConfiguration ...
imagePicker.captureSettings ...
imagePicker.appearance...
imagePicker.dataSource = ...
imagePicker.delegate = ...
navigationController.present(imagePicker, animated: true, completion: nil)
```

If you wish to present Image Picker as "keyboard" in your chat app, you have to set view controller's view as *inputView* of your first responder and:
- set view's autoresizing mask to `.flexibleHeight` if view's height should be default keyboard height
- set view's `frame.size.height` to get fixed height
To see an example how to set up Image Picker as an input view of a view controller refer to our Example App.

Optionaly, before presenting image picker, you can check if user has granted access permissions to Photos Library using `PHPhotoLibrary` API and ask for permissions. If you don't do it, image picker will take care of this automatically for you *after* it's presented.

## Accessing, selecting and deselecting asset items

All user actions such as selecting/deselecting of assets, taking new photos or livephotos or capturing vides are advertised using `ImagePickerControllerDelegate` delegate methods. For list and more detail explanation please see public header.

Sometimes you will need to manage selected assets programatically. Image Picker provides several convinience methods to work with asset items.

- `selectedAssets` property returns an array of currently selected `PHAsset` items
- to access asset items at certain indexes, use `assets(at:)` and `asset(at:)`
- to programatically select an asset item use `selectAsset(at:animated:scrollPosition:)`
- to programatically deselect an asset item use `deselectAsset(at:animated:)`
- to programatically deselect all selected items use `deselectAllAssets(_:)`

