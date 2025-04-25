/*************************************************************************/
/*  photo_picker.h                                                       */
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

#ifndef PHOTO_PICKER_H
#define PHOTO_PICKER_H

#include "core/version.h"

#if VERSION_MAJOR >= 4
#include "core/io/image.h"
#include "core/object/object.h"
#else
#include "core/image.h"
#include "core/object.h"
#endif

#ifdef __OBJC__
@class GodotPhotoPicker;
#else
typedef void GodotPhotoPicker;
#endif

class PhotoPicker : public Object {
	GDCLASS(PhotoPicker, Object);

	static void _bind_methods();

	GodotPhotoPicker *godot_photo_picker;

public:
	enum PhotoPickerSourceType {
		SOURCE_PHOTO_LIBRARY = 1 << 0,
		SOURCE_CAMERA_FRONT = 1 << 1,
		SOURCE_CAMERA_REAR = 1 << 2,
		SOURCE_SAVED_PHOTOS_ALBUM = 1 << 3,
	};

	enum PhotoPickerPermissionTarget {
		PERMISSION_TARGET_PHOTO_LIBRARY = 1 << 0,
		PERMISSION_TARGET_CAMERA = 1 << 1,
	};

	enum PhotoPickerPermissionStatus {
		PERMISSION_STATUS_UNKNOWN = 1 << 0,
		PERMISSION_STATUS_ALLOWED = 1 << 1,
		PERMISSION_STATUS_DENIED = 1 << 2,
	};

	static PhotoPicker *get_singleton();

	void present(PhotoPickerSourceType source);
	void request_permission(PhotoPickerPermissionTarget target);
	PhotoPickerPermissionStatus permission_status(PhotoPickerPermissionTarget target);

	void select_image(Ref<Image> image);
	void update_permission_status(PhotoPicker::PhotoPickerPermissionTarget target, PhotoPicker::PhotoPickerPermissionStatus status);

	PhotoPicker();
	~PhotoPicker();
};

VARIANT_ENUM_CAST(PhotoPicker::PhotoPickerSourceType)
VARIANT_ENUM_CAST(PhotoPicker::PhotoPickerPermissionTarget)
VARIANT_ENUM_CAST(PhotoPicker::PhotoPickerPermissionStatus)

#endif
