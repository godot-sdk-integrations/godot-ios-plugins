/*************************************************************************/
/*  photo_picker.cpp                                                     */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2021 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "photo_picker.h"

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

#if VERSION_MAJOR >= 4
#import "platform/ios/app_delegate.h"
#import "platform/ios/view_controller.h"
#else
#import "platform/iphone/app_delegate.h"
#import "platform/iphone/view_controller.h"
#endif

PhotoPicker *instance = NULL;

@interface GodotPhotoPicker : NSObject <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation GodotPhotoPicker

- (void)presentUsingSourceType:(PhotoPicker::PhotoPickerSourceType)source {
	_weakify(self);

	dispatch_async(dispatch_get_main_queue(), ^{
		_strongify(self);

		UIViewController *root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;

		if (!root_controller) {
			return;
		}

		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
		picker.delegate = self;

		switch (source) {
			case PhotoPicker::SOURCE_SAVED_PHOTOS_ALBUM:
				picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
				break;
			case PhotoPicker::SOURCE_PHOTO_LIBRARY:
				picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
				break;
			case PhotoPicker::SOURCE_CAMERA_REAR:
				picker.sourceType = UIImagePickerControllerSourceTypeCamera;
				picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
				break;
			case PhotoPicker::SOURCE_CAMERA_FRONT:
				picker.sourceType = UIImagePickerControllerSourceTypeCamera;
				picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
				break;
		}

		[root_controller presentViewController:picker animated:YES completion:nil];
	});
}

- (void)requestPermissionForTarget:(PhotoPicker::PhotoPickerPermissionTarget)target {
	switch (target) {
		case PhotoPicker::PERMISSION_TARGET_PHOTO_LIBRARY:
			switch ([PHPhotoLibrary authorizationStatus]) {
				case PHAuthorizationStatusLimited:
				case PHAuthorizationStatusAuthorized:
				case PHAuthorizationStatusDenied:
				case PHAuthorizationStatusRestricted:
					break;
				case PHAuthorizationStatusNotDetermined:
					[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus) {
						PhotoPicker::PhotoPickerPermissionStatus status = PhotoPicker::PERMISSION_STATUS_DENIED;

						switch (authorizationStatus) {
							case PHAuthorizationStatusLimited:
							case PHAuthorizationStatusAuthorized:
								status = PhotoPicker::PERMISSION_STATUS_ALLOWED;
								break;
							default:
								break;
						}
						PhotoPicker::get_singleton()->update_permission_status(target, status);
					}];
					break;
			}
			break;
		case PhotoPicker::PERMISSION_TARGET_CAMERA:
			switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
				case AVAuthorizationStatusAuthorized:
				case AVAuthorizationStatusDenied:
				case AVAuthorizationStatusRestricted:
					break;
				case AVAuthorizationStatusNotDetermined:
					[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
											 completionHandler:^(BOOL isAllowed) {
												 dispatch_async(dispatch_get_main_queue(), ^{
													 PhotoPicker::PhotoPickerPermissionStatus status = isAllowed ? PhotoPicker::PERMISSION_STATUS_ALLOWED : PhotoPicker::PERMISSION_STATUS_DENIED;
													 PhotoPicker::get_singleton()->update_permission_status(target, status);
												 });
											 }];
					break;
			}
			break;
	}
}

- (PhotoPicker::PhotoPickerPermissionStatus)permissionStatusForTarget:(PhotoPicker::PhotoPickerPermissionTarget)target {
	PhotoPicker::PhotoPickerPermissionStatus status = PhotoPicker::PERMISSION_STATUS_UNKNOWN;

	switch (target) {
		case PhotoPicker::PERMISSION_TARGET_PHOTO_LIBRARY:
			switch ([PHPhotoLibrary authorizationStatus]) {
				case PHAuthorizationStatusLimited:
				case PHAuthorizationStatusAuthorized:
					status = PhotoPicker::PERMISSION_STATUS_ALLOWED;
					break;
				case PHAuthorizationStatusDenied:
				case PHAuthorizationStatusRestricted:
					status = PhotoPicker::PERMISSION_STATUS_DENIED;
					break;
				case PHAuthorizationStatusNotDetermined:
					status = PhotoPicker::PERMISSION_STATUS_UNKNOWN;
					break;
			}
			break;
		case PhotoPicker::PERMISSION_TARGET_CAMERA:
			switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
				case AVAuthorizationStatusAuthorized:
					status = PhotoPicker::PERMISSION_STATUS_ALLOWED;
					break;
				case AVAuthorizationStatusDenied:
				case AVAuthorizationStatusRestricted:
					status = PhotoPicker::PERMISSION_STATUS_DENIED;
					break;
				case AVAuthorizationStatusNotDetermined:
					status = PhotoPicker::PERMISSION_STATUS_UNKNOWN;
					break;
			}
			break;
	}

	return status;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
	UIImage *image = info[UIImagePickerControllerOriginalImage];

	if (image) {
		CGImageRef cgImage = [[self class] newRGBA8CGImageFromUIImage:image];

		if (cgImage) {
			CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
			CFDataRef bmp = CGDataProviderCopyData(provider);
			const unsigned char *data = CFDataGetBytePtr(bmp);
			CFIndex length = CFDataGetLength(bmp);

			if (data) {
				Ref<Image> img;

#if VERSION_MAJOR >= 4
				Vector<uint8_t> img_data;
				img_data.resize(length);
				uint8_t* w = img_data.ptrw();
				memcpy(w, data, length);

				img.instantiate();
				img->set_data(image.size.width * image.scale, image.size.height * image.scale, 0, Image::FORMAT_RGBA8, img_data);
#else
				PoolVector<uint8_t> img_data;
				img_data.resize(length);
				PoolVector<uint8_t>::Write w = img_data.write();
				memcpy(w.ptr(), data, length);

				img.instance();
				img->create(image.size.width * image.scale, image.size.height * image.scale, 0, Image::FORMAT_RGBA8, img_data);
#endif

				PhotoPicker::get_singleton()->select_image(img);
			}

			CFRelease(bmp);
			CGImageRelease(cgImage);
		}
	}

	[picker dismissViewControllerAnimated:YES completion:nil];
}

+ (CGImageRef)newRGBA8CGImageFromUIImage:(UIImage *)image {
	size_t bitsPerPixel = 32;
	size_t bitsPerComponent = 8;
	size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;

	size_t width = image.size.width;
	size_t height = image.size.height;
	UIImageOrientation orientation = image.imageOrientation;

	size_t bytesPerRow = width * bytesPerPixel;

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	if (!colorSpace) {
		NSLog(@"Error allocating color space RGB");
		return NULL;
	}

	CGAffineTransform transform = CGAffineTransformIdentity;

	switch (orientation) {
		case UIImageOrientationDown:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, width, height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
			transform = CGAffineTransformTranslate(transform, width, 0);
			transform = CGAffineTransformRotate(transform, M_PI_2);
			break;
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, 0, height);
			transform = CGAffineTransformRotate(transform, -M_PI_2);
			break;
		default:
			break;
	}

	switch (orientation) {
		case UIImageOrientationUpMirrored:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, width, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, height, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
		default:
			break;
	}

	CGContextRef context = CGBitmapContextCreate(NULL,
			width,
			height,
			bitsPerComponent,
			bytesPerRow,
			colorSpace,
			kCGImageAlphaPremultipliedLast);

	CGImageRef newCGImage = NULL;

	if (!context) {
		NSLog(@"Bitmap context not created");
	} else {

		CGContextConcatCTM(context, transform);

		switch (orientation) {
			case UIImageOrientationLeft:
			case UIImageOrientationLeftMirrored:
			case UIImageOrientationRight:
			case UIImageOrientationRightMirrored:
				CGContextDrawImage(context, CGRectMake(0, 0, height, width), [image CGImage]);
				break;
			default:
				CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
				break;
		}

		newCGImage = CGBitmapContextCreateImage(context);
	}

	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);

	return newCGImage;
}

@end

PhotoPicker *PhotoPicker::get_singleton() {
	return instance;
}

void PhotoPicker::_bind_methods() {
	ClassDB::bind_method(D_METHOD("present", "mode"), &PhotoPicker::present);
	ClassDB::bind_method(D_METHOD("request_permission", "target"), &PhotoPicker::request_permission);
	ClassDB::bind_method(D_METHOD("permission_status", "target"), &PhotoPicker::permission_status);

	ADD_SIGNAL(MethodInfo("image_picked", PropertyInfo(Variant::OBJECT, "image")));
	ADD_SIGNAL(MethodInfo("permission_updated", PropertyInfo(Variant::INT, "target"), PropertyInfo(Variant::INT, "status")));

	BIND_ENUM_CONSTANT(SOURCE_PHOTO_LIBRARY);
	BIND_ENUM_CONSTANT(SOURCE_CAMERA_FRONT);
	BIND_ENUM_CONSTANT(SOURCE_CAMERA_REAR);
	BIND_ENUM_CONSTANT(SOURCE_SAVED_PHOTOS_ALBUM);

	BIND_ENUM_CONSTANT(PERMISSION_TARGET_PHOTO_LIBRARY);
	BIND_ENUM_CONSTANT(PERMISSION_TARGET_CAMERA);

	BIND_ENUM_CONSTANT(PERMISSION_STATUS_UNKNOWN);
	BIND_ENUM_CONSTANT(PERMISSION_STATUS_ALLOWED);
	BIND_ENUM_CONSTANT(PERMISSION_STATUS_DENIED);
}

void PhotoPicker::present(PhotoPickerSourceType source) {
	[godot_photo_picker presentUsingSourceType:source];
}

void PhotoPicker::request_permission(PhotoPicker::PhotoPickerPermissionTarget target) {
	[godot_photo_picker requestPermissionForTarget:target];
}

PhotoPicker::PhotoPickerPermissionStatus PhotoPicker::permission_status(PhotoPicker::PhotoPickerPermissionTarget target) {
	return [godot_photo_picker permissionStatusForTarget:target];
}

void PhotoPicker::select_image(Ref<Image> image) {
	emit_signal("image_picked", image);
}

void PhotoPicker::update_permission_status(PhotoPicker::PhotoPickerPermissionTarget target, PhotoPicker::PhotoPickerPermissionStatus status) {
	emit_signal("permission_updated", target, status);
}

PhotoPicker::PhotoPicker() {
	instance = this;

	godot_photo_picker = [[GodotPhotoPicker alloc] init];
}

PhotoPicker::~PhotoPicker() {
	instance = NULL;

	godot_photo_picker = nil;
}
