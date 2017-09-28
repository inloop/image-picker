# Image Picker

An easy to use drop-in framework providing user interface for taking pictures and videos and pick assets from Photo Library. User interface is designed to support `inputView` "keyboard-like" presentation for conversation user interfaces. Project is written in Swift4.

**Features:**
- presentation designed for chat apps as well as regular view controllers
- taking photos, live photos, capturing videos (wip)
- flip camera to front/rear
- turn on/off live photos
- save captured assets to Photo Library
- highly customisable UI

**Requirements**
- iOS 10+
- Xcode 9+
- Swift 4

**Installation**
- [Carthage](https://github.com/Carthage/Carthage)
- manually 

## Overview

A central object `ImagePickerController` manages user interactions and delivers the results of those interactions to a delegate object. The role and appearance of an image picker controller depend on the configuration you set up before presenting it.

Image Picker consists of 3 main functional parts:

1. **section of action items** - supports up to 2 custom action buttons, this section is optional and by default turned off.
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
- //TODO: document rest of vc properties!

### Capture settings

Currently Image Picker supports capturing *photos* and *live photos*. Videos will be supported soon. 

To configure Image Picker to support desired media type use `CaptureSettings` struct. Use property `cameraMode` to specify what kind of output you are interested in. If you don't intend to support live photos at all, please use value `photo`, otherwise `photoAndLivePhoto`.

By default, all captured assets are not saved to photo library but rather provided to you by the delegate right away. However if you wish to save assets to photo library set `savesCapturedAssetToPhotoLibrary` to *true*. 

An example of configuration for taking photos and live photos and saving them to photo library:

```
let imagePicker = ImagePickerController()
imagePicker.captureSettings.cameraMode = .photoAndLivePhoto
imagePicker.captureSettings.savesCapturedAssetToPhotoLibrary = true
```

Please refer to `CaptureSettings` public header for more information.

### Providing your own photos fetch result

By default Image Picker fetches from Photo Library 1000 recently added photos and videos. If you wish to provide your own fetch result please implement image picker controller's `assetsFetchResultBlock` block.

For example to fetch only live photos you can use following code snippet:

```
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

Image picker view hierarchy contains of `UICollectionView` to show action, camera and asset items and an overlay view to show permissions status. When custom cells are provided via `CellsRegistrator` it is your responsibility to do the styling as well styling custom overlay view for permissions status. However, few style attributes are supported such as background color. Please use custom appearance mechanism to achieve desired styling.

1. to style all image pickers globally use global appearance proxy object:
```
ImagePickerController.appearance().backgroundColor = UIColor.black
```

2. to style a particular instance of image picker use instances appearance proxy object:
```
let vc = ImagePickerController()
vc.appearance().backgroundColor = UIColor.black
```

For default styling attributes and more info please refer to public interface of `Appearance` class.

Please note that UIKit's appearance proxy is not currently supported.

### Defining layout using LayoutConfiguration

Image picker supports various kind of layouts and both vertical and horizontal scroll direction. Using `LayoutConfiguration` you can set layout that you need specifically to your app.

1. **Action Items** are always shown as first section and can contain up to 2 buttons. By default this section is turned off. Next example will show how to turn on both action items:
```
let imagePicker = ImagePickerController()
imagePicker.layoutConfiguration.showsFirstActionItem = true
imagePicker.layoutConfiguration.showsSecondActionItem = true
```

2. **Camera Item** is always shown in a section after action items section. So if action item if off this section is shown as first. Camera item section is by default on, so if you wish to turn it off use following code:
```
let imagePicker = ImagePickerController()
imagePicker.layoutConfiguration.showsCameraItem = false
```
> Please note that if you turn off camera section, Image Picker will not ask user for camera permissions.

3. **Asset Items** are always shown regardless if there are any photos in the app. You can control how many asset items are in a col or a row (based on scroll direction). By default, there are 2 asset in a col or a row. To change this to 1 see next snippet:
```
let imagePicker = ImagePickerController()
imagePicker.layoutConfiguration.numberOfAssetItemsInRow = 1
```
> Please note that provided value must be greater than 0 otherwise an exception will be thrown.

4. **Other layout properties**
 - *interitemSpacing* - spacing between items when laying out the grid
 - *actionSectionSpacing* - spacing between action items section and camera item section
 - *cameraSectionSpacing* - spacing between camera section and asset items section
 - *contentInset* - collection view content inset

### Providing custom views

All views used by Image Picker can be provided by you to achieve highly customisable UI that fits your app the best. As mentioned earlier, whole UI consists of a collection view and an overlay view.

- **collection view** displays cells to display action, camera and asset items. To register custom cells use `CellsRegistrator`. It contains API to register both nibs and classes for each section type. For example to register custom cells for action items section use following code:
```
let imagePicker = ImagePickerController()
imagePicker.cellsRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
```
Same principle is applied to registering custom camera and asset items. You can also set specific cells for each asset media types such photos and videos. For example to use specific cell for video  assets use:
```
let imagePicker = ImagePickerController()
imagePicker.cellsRegistrator.register(cellClass: VideoCell.self, forAssetItemOf: .video)
imagePicker.cellsRegistrator.register(cellClass: ImageCell.self, forAssetItemOf: .image)
```
> *Note:* Please make sure that if you use custom cells you register cells for all media types (audio, video) otherwise Image Picker will throw an exception. Please don't forget that camera item cells **must** subclass CameraCollectionViewCell and asset items cells **must** conform to `ImagePickerAssetCell` protocol. You can also fine-tune your asset cells to a specific asset types such us live photos, panorama photos, etc. using the delegate. Please see our ExampleApp for implementation details.

- **overlay view** is shown over collection view in situations when app does not have access permissions to *Photos Library*. To support overlay view please implement a datasource conforming to `ImagePickerControllerDatasource` protocol. Possible implementation could look like this:
```
extension ViewController: ImagePickerControllerDataSource {
    func imagePicker(controller: ImagePickerController, viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView {
        let statusView = CustomPermissionStatusView(frame: .zero)
        //configure and return view based on authorization status
        return statusView
    }
}
```

### Implementing custom camera cell

Image picker provides a default camera cell that just shows a camera output and captures a photo when user taps it. 

If you wish to implement fancier features such as custom buttons, camera flipping, taking live photos, showing camera current permissions, updating live photo statuses you have to provide your own subclass of `CameraCollectionViewCell` and implement dedicated methods.

To see an example of custom implementation that supports all mentioned features please see class `LivePhotoCameraCell` of *ExampleApp*.

### Implementing custom assets cell

Image picker provides a default assets cell that shows an image thumbnail and selected state. If you wish to provide custom asset cell, that could show for example asset's media subtype (live photo, panorama, HDR, screenshot, streamed video, etc.) simply provide your own asset cell class that conforms to `ImagePickerAssetCell` and in implement image picker delegate's `func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset)` method. Possible example implementation could be:

```
func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset) {
        switch cell {
        
        case let videoCell as VideoCell:
            videoCell.label.text = ViewController.durationFormatter.string(from: asset.duration)
        
        case let imageCell as ImageCell:
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

Please for more info and detailed implementation see our ExampleApp and ImageCell class and nib.

## Presentation

If you wish to present Image Picker in default set up, you don't need to do any special configuration, simple create new instance and present a view controller:

```
let imagePicker = ImagePickerController()
navigationController.present(imagePicker, animated: true, completion: nil)
```

However, most of the time you will want to do custom configuration so please do all the configuration before the view controller's view is loaded (`viewDidLoad()` method is called).

```
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

## Features to add

1. landscape layout for camera cell - video is already in landscape but cell must be wider to properly display it
2. [ok] flip cameras
3. [ok] blur/unblur camera cell video layer when capture session is suspended/unsuspended
4. [ok] blur/unblur camera cell video layer when capture session is interrupted, failed or app goes to background/unactive
5. add public API for recording videos
6. [ok] add public API for enabling/disabling live photos
7. [ok] add public API for setting if taken pictures should be saved in camera roll or just directly provided through delegate
8. [ok] when user denies access to camera,  show that access is denied
9. implement image pre-caching based on visible rectangle bounds
10. [ok] add default features for base CameraCollectionViewCell - tap to take photo
11. [ok] support styling through appearance
12. [ok] configuration-less default implementation

## Known Issues

1. autorotate to landsacpe on iPhone X does not work properly - safe area is not updated so layout is broken
2. [fixex] live photos does not work - it says device does not support live photos event thought all shold be set correctly (does not work on SE nor iPhone 7) -> this is because session preset is to video, see comments in code to fix it
3. [fixed] flipping camera animation is flickering, I could not find a proper way how to achieve nice animation with blurred content, I tried following solutions:
    1. adding UIVisualEffectsView as subview of camera output but it's flickering when camera goes black on a while
    2. taking screenshot of AVVideoPreviewLayer is not possible - it returns transparent empty image
    used solution: use image buffer from AVVideoCaptureOutupt, blur it and add it as subview to the cell
    [fixed] need to transform image from front camera horizontally - it's mirrored so the blurring effect is not 100% nice when flipping camera
4. [fixed] when camera cell will be blurred first time it lags - need to use instruments to find out why it's lagging
    reproduce: simple scroll camera cell so it's not visible, you will notice a lag (iPhone SE), this lag might be caused by Photos framework when loading first buch of images
5. when rotating device, there is a little lag in video when changing orientation of outputs - it should be smooth though
6. [fixed] when flipping from front camera to back camera, latest sample buffer image that is used does not have proper transform, you can see that it is rotated horizontally so it creates unpleasant effect durring unblur animation when flipping cameras
7. [fixed] when user defines layout configuration without camera - image picker still initializes capture session wich asks for permissions, crashes if no privacy key in info.plist is set and this is all not necessary


## Technologies used

1. UICollectionView - for laying out views, we decided to use regular horizontal flow layout with implemented flow delegate. Nicer solution in terms of clean code would be to use custom layout, but most of the flow layout would have to be replicated.
2. AVCaptureSession - for capturing video on input and output. At first we tried to exploit UIImagePickerController, however apart from it's hacky, there were 3 problems with this solution:
    1. presenting image picker was causing a lag that was not possible to remove
    2. video output view was not rotating properly when interface was rotating and there was no API to rotate it manually
    3. when video output is not more visible on screen (user scrolled elsewhere) there was no API to resume/suspend the capture session and that is wasting resources
3. By using custom capture session instead of using existing UIImagePickerController we gained much of flexibility, but on the other side we had to reimplement many features such us:
    1. bluring / unbluring video output when capture session is suspended / resumed - to achieve this we used latest frame from sample buffer and added is as blurred UIImageView subview. To collect recent frame from sample buffer we had to implement custom video data output and remember latest frame from the buffer. This is then converted to UIImage and used with the visual effect view.
    2. flipping front / rear camera - we use method similar to mentioned in point 1.

