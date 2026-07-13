/**************************************************************************/
/*  camera_ios_4x.mm                                                      */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

#include "core/version.h"

#if VERSION_MAJOR == 4 && VERSION_MINOR < 7

///@TODO this is a near duplicate of CameraMacOS, we should find a way to combine those to minimize code duplication!!!!
// If you fix something here, make sure you fix it there as well!

#include "camera_ios.h"

#include "core/math/math_defs.h"
#include "servers/camera/camera_feed.h"

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

//////////////////////////////////////////////////////////////////////////
// MyCaptureSession - This is a little helper class so we can capture our frames

@interface MyCaptureSession : AVCaptureSession <AVCaptureVideoDataOutputSampleBufferDelegate> {
	Ref<CameraFeed> feed;
	size_t width[2];
	size_t height[2];
	Vector<uint8_t> img_data[2];

	AVCaptureDeviceInput *input;
	AVCaptureVideoDataOutput *output;
}

@end

@implementation MyCaptureSession

- (id)initForFeed:(Ref<CameraFeed>)p_feed andDevice:(AVCaptureDevice *)p_device withFormat:(int)p_format {
	if (self = [super init]) {
		NSError *error;
		feed = p_feed;
		width[0] = 0;
		height[0] = 0;
		width[1] = 0;
		height[1] = 0;

		// prepare our device
		if ([p_device lockForConfiguration:&error]) {
			// Set default modes to continuous auto for natural camera behavior.
			if ([p_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
				[p_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			}
			if ([p_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
				[p_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
			}
			if ([p_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
				[p_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
			}

			[p_device unlockForConfiguration];
		} else {
			print_line("Couldn't lock device for configuration");
		}

		[self beginConfiguration];

		// setup our capture
		if (p_format != -1) {
			if ([self canSetSessionPreset:AVCaptureSessionPresetInputPriority]) {
				self.sessionPreset = AVCaptureSessionPresetInputPriority;
			} else {
				print_line("Warning: AVCaptureSessionPresetInputPriority not supported");
			}
		} else {
			if ([self canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
				self.sessionPreset = AVCaptureSessionPreset1280x720;
			} else if ([self canSetSessionPreset:AVCaptureSessionPresetHigh]) {
				self.sessionPreset = AVCaptureSessionPresetHigh;
			} else {
				print_line("Warning: No suitable session preset found, using device default");
			}
		}

		input = [AVCaptureDeviceInput deviceInputWithDevice:p_device error:&error];
		if (!input) {
			print_line("Couldn't get input device for camera");
			[self commitConfiguration];
			return nil;
		}
		if (![self canAddInput:input]) {
			print_line("Couldn't add input to capture session");
			input = nullptr;
			[self commitConfiguration];
			return nil;
		}
		[self addInput:input];

		output = [AVCaptureVideoDataOutput new];
		if (!output) {
			print_line("Couldn't get output device for camera");
			[self removeInput:input];
			input = nullptr;
			[self commitConfiguration];
			return nil;
		}
		if (![self canAddOutput:output]) {
			print_line("Couldn't add output to capture session");
			[self removeInput:input];
			input = nullptr;
			output = nullptr;
			[self commitConfiguration];
			return nil;
		}

		// Use the camera's native pixel format (typically VideoRange YCbCr).
		// This matches ARKit's output format and Godot's shader expectations.
		// Note: 10-bit formats are filtered in get_formats(), so only 8-bit
		// formats will be selected via set_format().

		// discard if the data output queue is blocked (as we process the still image)
		[output setAlwaysDiscardsLateVideoFrames:YES];

		// now set ourselves as the delegate to receive new frames.
		[output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

		// this takes ownership
		[self addOutput:output];

		[self commitConfiguration];

		// kick off our session..
		[self startRunning];
	};
	return self;
}

- (void)cleanup {
	// stop running
	[self stopRunning];

	// cleanup
	[self beginConfiguration];

	// remove input
	if (input) {
		[self removeInput:input];
		// don't release this
		input = nullptr;
	}

	// free up our output
	if (output) {
		[self removeOutput:output];
		[output setSampleBufferDelegate:nil queue:nullptr];
		output = nullptr;
	}

	[self commitConfiguration];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	// This gets called every time our camera has a new image for us to process.
	// May need to investigate in a way to throttle this if we get more images then we're rendering frames..

	// For now, version 1, we're just doing the bare minimum to make this work...
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if (pixelBuffer == nullptr) {
		return;
	}

	// It says that we need to lock this on the documentation pages but it's not in the samples
	// need to lock our base address so we can access our pixel buffers, better safe then sorry?
	CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

	// Check if we have the expected number of planes (Y and CbCr).
	size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
	if (planeCount < 2) {
		static bool plane_count_error_logged = false;
		if (!plane_count_error_logged) {
			ERR_PRINT("Unexpected plane count in pixel buffer (expected 2, got " + itos(planeCount) + ")");
			plane_count_error_logged = true;
		}
		CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
		return;
	}

	// get our buffers
	unsigned char *dataY = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
	unsigned char *dataCbCr = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
	if (dataY == nullptr || dataCbCr == nullptr) {
		static bool buffer_access_error_logged = false;
		if (!buffer_access_error_logged) {
			ERR_PRINT("Couldn't access pixel buffer plane data");
			buffer_access_error_logged = true;
		}
		CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
		return;
	}

	Ref<Image> img[2];

	{
		// do Y
		size_t new_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
		size_t new_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
		size_t row_stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

		if ((width[0] != new_width) || (height[0] != new_height)) {
			width[0] = new_width;
			height[0] = new_height;
			img_data[0].resize(new_width * new_height);
		}

		uint8_t *w = img_data[0].ptrw();
		if (new_width == row_stride) {
			memcpy(w, dataY, new_width * new_height);
		} else {
			for (size_t i = 0; i < new_height; i++) {
				memcpy(w, dataY, new_width);
				w += new_width;
				dataY += row_stride;
			}
		}

		img[0].instantiate();
		img[0]->set_data(new_width, new_height, 0, Image::FORMAT_R8, img_data[0]);
	}

	{
		// do CbCr
		size_t new_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
		size_t new_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
		size_t row_stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

		if ((width[1] != new_width) || (height[1] != new_height)) {
			width[1] = new_width;
			height[1] = new_height;
			img_data[1].resize(2 * new_width * new_height);
		}

		uint8_t *w = img_data[1].ptrw();
		if (new_width * 2 == row_stride) {
			memcpy(w, dataCbCr, 2 * new_width * new_height);
		} else {
			for (size_t i = 0; i < new_height; i++) {
				memcpy(w, dataCbCr, new_width * 2);
				w += new_width * 2;
				dataCbCr += row_stride;
			}
		}

		/// TODO OpenGL doesn't support FORMAT_RG8, need to do some form of conversion
		img[1].instantiate();
		img[1]->set_data(new_width, new_height, 0, Image::FORMAT_RG8, img_data[1]);
	}

	// set our texture...
#if VERSION_MINOR >= 4
	feed->set_ycbcr_images(img[0], img[1]);
#else
	feed->set_YCbCr_imgs(img[0], img[1]);
#endif

	// and unlock
	CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
}

@end

//////////////////////////////////////////////////////////////////////////
// CameraFeedIOS - Subclass for camera feeds in iOS

class CameraFeedIOS : public CameraFeed {
#if VERSION_MINOR >= 5
	GDSOFTCLASS(CameraFeedIOS, CameraFeed);
#endif
private:
	AVCaptureDevice *device;
	MyCaptureSession *capture_session;
	bool device_locked;
	bool was_active_before_pause = false;
	int current_orientation = 1; // UIInterfaceOrientation value (1 = Portrait)

public:
	AVCaptureDevice *get_device() const;

	CameraFeedIOS();
	~CameraFeedIOS();

	void set_device(AVCaptureDevice *p_device);

	void handle_rotation_change(int p_orientation);
	void handle_pause();
	void handle_resume();

#if VERSION_MINOR >= 5
	bool activate_feed() override;
	void deactivate_feed() override;

	bool set_format(int p_index, const Dictionary &p_parameters) override;
	Array get_formats() const override;
#else
	bool activate_feed();
	void deactivate_feed();
#endif
};

AVCaptureDevice *CameraFeedIOS::get_device() const {
	return device;
}

CameraFeedIOS::CameraFeedIOS() {
	device = nullptr;
	capture_session = nullptr;
	device_locked = false;
}

CameraFeedIOS::~CameraFeedIOS() {
	if (is_active()) {
		deactivate_feed();
	}
}

void CameraFeedIOS::set_device(AVCaptureDevice *p_device) {
	ERR_FAIL_NULL(p_device);
	device = p_device;

#if VERSION_MINOR >= 5
	// Reset format selection when switching devices.
	selected_format = -1;
#endif

	// get some info
	NSString *device_name = p_device.localizedName;
	name = String::utf8(device_name.UTF8String);
	position = CameraFeed::FEED_UNSPECIFIED;
	if ([p_device position] == AVCaptureDevicePositionBack) {
		position = CameraFeed::FEED_BACK;
	} else if ([p_device position] == AVCaptureDevicePositionFront) {
		position = CameraFeed::FEED_FRONT;
	};
}

void CameraFeedIOS::handle_rotation_change(int p_orientation) {
	current_orientation = p_orientation;

	// UIInterfaceOrientation values:
	// 1 = UIInterfaceOrientationPortrait
	// 2 = UIInterfaceOrientationPortraitUpsideDown
	// 3 = UIInterfaceOrientationLandscapeLeft
	// 4 = UIInterfaceOrientationLandscapeRight
	int display_rotation = 0;
	switch (current_orientation) {
		case 1:
			display_rotation = 0;
			break;
		case 2:
			display_rotation = 180;
			break;
		case 3:
			display_rotation = 270;
			break;
		case 4:
			display_rotation = 90;
			break;
		default:
			display_rotation = 0;
			break;
	}

	// iOS camera sensor orientation is 90 degrees (same as Android).
	int sensor_orientation = 90;
	int sign = position == CameraFeed::FEED_FRONT ? 1 : -1;
	float image_rotation = (sensor_orientation - display_rotation * sign + 360) % 360;

	transform = Transform2D();
	transform = transform.rotated(Math::deg_to_rad(image_rotation));
}

void CameraFeedIOS::handle_pause() {
	if (capture_session) {
		was_active_before_pause = true;
		deactivate_feed();
	} else {
		was_active_before_pause = false;
	}
}

void CameraFeedIOS::handle_resume() {
	if (was_active_before_pause) {
		activate_feed();
		was_active_before_pause = false;
	}
}

static bool is_supported_format(FourCharCode fourcc) {
	switch (fourcc) {
		// 8-bit YCbCr formats.
		// 10-bit and compressed formats are excluded because
		// Godot's Image class only supports 8-bit formats.
		case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
		case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
		case kCVPixelFormatType_422YpCbCr8BiPlanarFullRange:
		case kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange:
		// RGB formats (always full range).
		case kCVPixelFormatType_32BGRA:
		case kCVPixelFormatType_32RGBA:
			return true;
		default:
			return false;
	}
}

bool CameraFeedIOS::activate_feed() {
	ERR_FAIL_NULL_V(device, false);
	if (capture_session) {
		// Already recording.
		return true;
	}

#if VERSION_MINOR >= 5
	// Configure device format if specified.
	// selected_format is a filtered index (matching get_formats()), so we need to
	// iterate through formats to find the matching one.
	if (selected_format != -1) {
		int current_index = 0;
		AVCaptureDeviceFormat *target_format = nil;

		for (AVCaptureDeviceFormat *format in device.formats) {
			CMFormatDescriptionRef formatDescription = format.formatDescription;
			FourCharCode fourcc = CMFormatDescriptionGetMediaSubType(formatDescription);

			// Skip unsupported formats to match get_formats() indexing.
			if (!is_supported_format(fourcc)) {
				continue;
			}

			for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
				(void)range; // Unused, only counting indices.
				if (current_index == selected_format) {
					target_format = format;
					break;
				}
				current_index++;
			}
			if (target_format) {
				break;
			}
		}

		if (target_format) {
			NSError *error;
			if (!device_locked) {
				device_locked = [device lockForConfiguration:&error];
				ERR_FAIL_COND_V_MSG(!device_locked, false, error.localizedFailureReason.UTF8String);
			}
			[device setActiveFormat:target_format];
		} else {
			ERR_PRINT("Failed to find format for selected_format index, using device default");
			selected_format = -1;
		}
	}
#endif

	// Start camera capture, check permission.
#if VERSION_MINOR >= 5
	int format_index = selected_format;
#else
	int format_index = -1;
#endif
	AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
	if (status == AVAuthorizationStatusAuthorized) {
		capture_session = [[MyCaptureSession alloc] initForFeed:this andDevice:device withFormat:format_index];
		return capture_session != nullptr;
	} else if (status == AVAuthorizationStatusNotDetermined) {
		// Request permission asynchronously.
		[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
								 completionHandler:^(BOOL granted) {
									 if (granted) {
										 capture_session = [[MyCaptureSession alloc] initForFeed:this andDevice:device withFormat:format_index];
									 }
								 }];
		return false;
	} else if (status == AVAuthorizationStatusDenied) {
		print_line("Camera permission denied by user.");
		return false;
	} else if (status == AVAuthorizationStatusRestricted) {
		print_line("Camera access restricted.");
		return false;
	}

	return false;
}

void CameraFeedIOS::deactivate_feed() {
	// end camera capture if we have one
	if (capture_session) {
		[capture_session cleanup];
		capture_session = nullptr;
	};
	if (device_locked) {
		[device unlockForConfiguration];
		device_locked = false;
	}
}

#if VERSION_MINOR >= 5
bool CameraFeedIOS::set_format(int p_index, const Dictionary &p_parameters) {
	ERR_FAIL_NULL_V(device, false);
	if (p_index == -1) {
		selected_format = p_index;
		if (is_active()) {
			[capture_session beginConfiguration];
			capture_session.sessionPreset = AVCaptureSessionPreset1280x720;
		}
		if (device_locked) {
			[device unlockForConfiguration];
			device_locked = false;
		}
		if (is_active()) {
			[capture_session commitConfiguration];
		}
		return true;
	}

	// Find the device format and frame rate range corresponding to p_index.
	// get_formats() returns one entry per frame rate range, so we need to
	// iterate through all formats and their frame rate ranges to find the match.
	int current_index = 0;
	AVCaptureDeviceFormat *target_format = nil;
	AVFrameRateRange *target_range = nil;

	for (AVCaptureDeviceFormat *format in device.formats) {
		CMFormatDescriptionRef formatDescription = format.formatDescription;
		FourCharCode fourcc = CMFormatDescriptionGetMediaSubType(formatDescription);

		// Skip unsupported formats to match get_formats() indexing.
		if (!is_supported_format(fourcc)) {
			continue;
		}

		for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
			if (current_index == p_index) {
				target_format = format;
				target_range = range;
				break;
			}
			current_index++;
		}
		if (target_format) {
			break;
		}
	}

	ERR_FAIL_NULL_V_MSG(target_format, false, "Invalid format index");

	if (is_active()) {
		if (!device_locked) {
			NSError *error;
			device_locked = [device lockForConfiguration:&error];
			ERR_FAIL_COND_V_MSG(!device_locked, false, error.localizedFailureReason.UTF8String);
		}
		[capture_session beginConfiguration];
		capture_session.sessionPreset = AVCaptureSessionPresetInputPriority;
		[device setActiveFormat:target_format];
		[device setActiveVideoMinFrameDuration:target_range.minFrameDuration];
		[device setActiveVideoMaxFrameDuration:target_range.minFrameDuration];
	}
	selected_format = p_index;
	if (is_active()) {
		[capture_session commitConfiguration];
	}
	return true;
}

static String get_format_name(FourCharCode fourcc) {
	switch (fourcc) {
		// 8-bit YCbCr 4:2:0
		case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
		case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
			return "YUV420";
		// 8-bit YCbCr 4:2:2
		case kCVPixelFormatType_422YpCbCr8BiPlanarFullRange:
		case kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange:
			return "YUV422";
		// RGB/BGRA
		case kCVPixelFormatType_32BGRA:
			return "BGRA";
		case kCVPixelFormatType_32RGBA:
			return "RGBA";
		default:
			// Return FourCC string for unknown formats.
			return String::chr((char)(fourcc >> 24) & 0xFF) +
				   String::chr((char)(fourcc >> 16) & 0xFF) +
				   String::chr((char)(fourcc >> 8) & 0xFF) +
				   String::chr((char)(fourcc >> 0) & 0xFF);
	}
}

static String get_color_range(FourCharCode fourcc) {
	switch (fourcc) {
		case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
		case kCVPixelFormatType_422YpCbCr8BiPlanarFullRange:
			return "full";
		case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
		case kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange:
			return "video";
		default:
			return "";
	}
}

Array CameraFeedIOS::get_formats() const {
	ERR_FAIL_NULL_V(device, Array());
	Array result;
	for (AVCaptureDeviceFormat *format in device.formats) {
		CMFormatDescriptionRef formatDescription = format.formatDescription;
		FourCharCode fourcc = CMFormatDescriptionGetMediaSubType(formatDescription);

		// Skip unsupported formats (10-bit, compressed, etc.)
		if (!is_supported_format(fourcc)) {
			continue;
		}

		CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(formatDescription);
		String format_name = get_format_name(fourcc);

		// Determine color range from pixel format
		String color_range = get_color_range(fourcc);

		// Add an entry for each supported frame rate range.
		for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
			Dictionary dictionary;
			dictionary["width"] = dimension.width;
			dictionary["height"] = dimension.height;
			dictionary["format"] = format_name;
			if (!color_range.is_empty()) {
				dictionary["color_range"] = color_range;
			}

			// Use minFrameDuration to get the maximum frame rate.
			// CMTime: value is numerator, timescale is denominator (units per second).
			// Frame rate = timescale / value.
			CMTime duration = range.minFrameDuration;
			dictionary["frame_numerator"] = (int64_t)duration.timescale;
			dictionary["frame_denominator"] = (int64_t)duration.value;

			result.push_back(dictionary);
		}
	}
	return result;
}
#endif

//////////////////////////////////////////////////////////////////////////
// MyDeviceNotifications - This is a little helper class gets notifications
// when devices are connected/disconnected

@interface MyDeviceNotifications : NSObject {
	CameraIOS *camera_server;
}

@end

@implementation MyDeviceNotifications

- (void)devices_changed:(NSNotification *)notification {
	camera_server->update_feeds();
}

- (id)initForServer:(CameraIOS *)p_server {
	if (self = [super init]) {
		camera_server = p_server;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(devices_changed:) name:AVCaptureDeviceWasConnectedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(devices_changed:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
	};
	return self;
}

- (void)dealloc {
	// remove notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceWasConnectedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceWasDisconnectedNotification object:nil];
}

@end

MyDeviceNotifications *device_notifications = nil;

//////////////////////////////////////////////////////////////////////////
// CameraIOS - Subclass for our camera server on iOS

void CameraIOS::update_feeds() {
	NSMutableArray *deviceTypes = [NSMutableArray array];

	[deviceTypes addObject:AVCaptureDeviceTypeBuiltInWideAngleCamera];
	[deviceTypes addObject:AVCaptureDeviceTypeBuiltInTelephotoCamera];

	if (@available(iOS 10.2, *)) {
		[deviceTypes addObject:AVCaptureDeviceTypeBuiltInDualCamera];
	}

	if (@available(iOS 11.1, *)) {
		[deviceTypes addObject:AVCaptureDeviceTypeBuiltInTrueDepthCamera];
	}

	AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession
			discoverySessionWithDeviceTypes:deviceTypes
								  mediaType:AVMediaTypeVideo
								   position:AVCaptureDevicePositionUnspecified];

	NSArray<AVCaptureDevice *> *devices = session.devices;

	// Deactivate feeds that are gone before removing them.
	for (int i = feeds.size() - 1; i >= 0; i--) {
		Ref<CameraFeedIOS> feed = (Ref<CameraFeedIOS>)feeds[i];
		if (feed.is_null()) {
			continue;
		}

		if (![devices containsObject:feed->get_device()]) {
			if (feed->is_active()) {
				feed->deactivate_feed();
			}
			remove_feed(feed);
		};
	};

	for (AVCaptureDevice *device in devices) {
		bool found = false;
		for (int i = 0; i < feeds.size() && !found; i++) {
			Ref<CameraFeedIOS> feed = (Ref<CameraFeedIOS>)feeds[i];
			if (feed.is_null()) {
				continue;
			}
			if (feed->get_device() == device) {
				found = true;
			};
		};

		if (!found) {
			Ref<CameraFeedIOS> newfeed;
			newfeed.instantiate();
			newfeed->set_device(device);
			add_feed(newfeed);
		};
	};

	// Update rotation for all feeds.
	UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
	if (@available(iOS 13, *)) {
		UIWindow *window = [UIApplication sharedApplication].delegate.window;
		UIWindowScene *windowScene = window.windowScene;
		if (windowScene) {
			orientation = windowScene.interfaceOrientation;
		}
	} else {
		orientation = [[UIApplication sharedApplication] statusBarOrientation];
	}
#if VERSION_MINOR >= 6
	handle_display_rotation_change((int)orientation);
#else
	current_orientation = (int)orientation;
	for (int i = 0; i < feeds.size(); i++) {
		Ref<CameraFeedIOS> feed = (Ref<CameraFeedIOS>)feeds[i];
		if (feed.is_valid()) {
			feed->handle_rotation_change(current_orientation);
		}
	}
#endif

#if VERSION_MINOR >= 5
	emit_signal(SNAME(CameraServer::feeds_updated_signal_name));
#endif
}

#if VERSION_MINOR >= 5
void CameraIOS::set_monitoring_feeds(bool p_monitoring_feeds) {
	if (p_monitoring_feeds == monitoring_feeds) {
		return;
	}

	CameraServer::set_monitoring_feeds(p_monitoring_feeds);
	if (p_monitoring_feeds) {
		// Find available cameras we have at this time.
		update_feeds();

		// Get notified on feed changes.
		device_notifications = [[MyDeviceNotifications alloc] initForServer:this];
	} else {
		// Stop monitoring feed changes.
		device_notifications = nil;
	}
}
#endif

#if VERSION_MINOR >= 6
void CameraIOS::handle_display_rotation_change(int p_orientation) {
	current_orientation = p_orientation;

	for (int i = 0; i < feeds.size(); i++) {
		Ref<CameraFeedIOS> feed = (Ref<CameraFeedIOS>)feeds[i];
		if (feed.is_valid()) {
			feed->handle_rotation_change(p_orientation);
		}
	}
}

void CameraIOS::handle_application_pause() {
	for (int i = 0; i < feeds.size(); i++) {
		Ref<CameraFeedIOS> feed = (Ref<CameraFeedIOS>)feeds[i];
		if (feed.is_valid()) {
			feed->handle_pause();
		}
	}
}

void CameraIOS::handle_application_resume() {
	for (int i = 0; i < feeds.size(); i++) {
		Ref<CameraFeedIOS> feed = (Ref<CameraFeedIOS>)feeds[i];
		if (feed.is_valid()) {
			feed->handle_resume();
		}
	}
}
#endif

CameraIOS::CameraIOS() {
	// check if we have our usage description
	NSString *usage_desc = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSCameraUsageDescription"];
	if (usage_desc == nullptr) {
		// don't initialise if we don't get anything
		print_line("No NSCameraUsageDescription key in pList, no access to cameras.");
		return;
	} else if (usage_desc.length == 0) {
		// don't initialise if we don't get anything
		print_line("Empty NSCameraUsageDescription key in pList, no access to cameras.");
		return;
	}

#if VERSION_MINOR < 5
	// now we'll request access.
	// If this is the first time the user will be prompted with the string (iOS will read it).
	// Once a decision is made it is returned. If the user wants to change it later on they
	// need to go into setting.
	print_line("Requesting Camera permissions");

	[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
							 completionHandler:^(BOOL granted) {
								 if (granted) {
									 print_line("Access to cameras granted!");

									 // Find available cameras we have at this time
									 update_feeds();

									 // should only have one of these....
									 device_notifications = [[MyDeviceNotifications alloc] initForServer:this];
								 } else {
									 print_line("No access to cameras!");
								 }
							 }];
#endif
}

CameraIOS::~CameraIOS() {
	device_notifications = nil;
}

#endif // VERSION_MAJOR == 4
