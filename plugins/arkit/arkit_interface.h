/*************************************************************************/
/*  arkit_interface.h                                                    */
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

#ifndef ARKIT_INTERFACE_H
#define ARKIT_INTERFACE_H

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "servers/xr/xr_interface.h"
#include "servers/xr/xr_positional_tracker.h"
#include "arkit_anchor_mesh.h"

typedef XRInterface GodotBaseARInterface;
typedef ARKitAnchorMesh GodotARTracker;

typedef Vector<uint8_t> GodotUInt8Vector;

#define GODOT_ARKIT_OVERRIDE override
#else
#include "servers/arvr/arvr_interface.h"
#include "servers/arvr/arvr_positional_tracker.h"

typedef ARVRInterface GodotBaseARInterface;
typedef ARVRPositionalTracker GodotARTracker;

typedef PoolVector<uint8_t> GodotUInt8Vector;

#define GODOT_ARKIT_OVERRIDE
#endif

#include "servers/camera/camera_feed.h"

/**
	@author Bastiaan Olij <mux213@gmail.com>

	ARKit interface between iOS and Godot
*/

// forward declaration for some needed objects
class ARKitShader;

#ifdef __OBJC__
typedef NSObject GodotARAnchor;
#else
typedef void GodotARAnchor;
#endif

class ARKitInterface : public GodotBaseARInterface {
	GDCLASS(ARKitInterface, GodotBaseARInterface);

private:
	bool initialized;
	bool session_was_started;
	bool plane_detection_is_enabled;
	bool light_estimation_is_enabled;
	real_t ambient_intensity;
	real_t ambient_color_temperature;
	real_t exposure_offset;

	Ref<XRPositionalTracker> m_head;
	Transform3D transform;
	Projection projection;
	float eye_height, z_near, z_far;

	Ref<CameraFeed> feed;
	size_t image_width[2];
	size_t image_height[2];
	GodotUInt8Vector img_data[2];

#if VERSION_MAJOR == 4
	XRInterface::TrackingStatus tracking_state;
#endif

	struct anchor_map {
		GodotARTracker *tracker;
		unsigned char uuid[16];
	};

	///@TODO should use memory map object from Godot?
	unsigned int num_anchors;
	unsigned int max_anchors;
	anchor_map *anchors;
	GodotARTracker *get_anchor_for_uuid(const unsigned char *p_uuid);
	void remove_anchor_for_uuid(const unsigned char *p_uuid);
	void remove_all_anchors();

protected:
	static void _bind_methods();

public:
	void start_session();
	void stop_session();
	
	bool get_light_estimation_is_enabled() const;
	void set_light_estimation_is_enabled(bool p_enable);

	real_t get_ambient_intensity() const;
	real_t get_ambient_color_temperature() const;
	real_t get_exposure_offset() const;

	/* while Godot has its own raycast logic this takes ARKits camera into account and hits on any ARAnchor */
	Array raycast(Vector2 p_screen_coord);

	virtual StringName get_name() const GODOT_ARKIT_OVERRIDE;
	virtual uint32_t get_capabilities() const GODOT_ARKIT_OVERRIDE;

	virtual bool is_initialized() const GODOT_ARKIT_OVERRIDE;
	virtual bool initialize() GODOT_ARKIT_OVERRIDE;
	virtual void uninitialize() GODOT_ARKIT_OVERRIDE;
	virtual Dictionary get_system_info() GODOT_ARKIT_OVERRIDE;

	/** input and output **/
 	virtual TrackingStatus get_tracking_status() const GODOT_ARKIT_OVERRIDE { return tracking_state; };
	
	/** specific to AR **/
	virtual bool get_anchor_detection_is_enabled() const GODOT_ARKIT_OVERRIDE;
	virtual void set_anchor_detection_is_enabled(bool p_enable) GODOT_ARKIT_OVERRIDE;
	virtual int get_camera_feed_id() GODOT_ARKIT_OVERRIDE;

	/** rendering and internal **/

	virtual Transform3D get_camera_transform() GODOT_ARKIT_OVERRIDE;
	virtual void process() GODOT_ARKIT_OVERRIDE;

	virtual Size2 get_render_target_size() GODOT_ARKIT_OVERRIDE;
	virtual uint32_t get_view_count() GODOT_ARKIT_OVERRIDE;
	virtual Transform3D get_transform_for_view(uint32_t p_view, const Transform3D &p_cam_transform) GODOT_ARKIT_OVERRIDE;
	virtual Projection get_projection_for_view(uint32_t p_view, double p_aspect, double p_z_near, double p_z_far) GODOT_ARKIT_OVERRIDE;
	
	virtual Vector<BlitToScreen> post_draw_viewport(RID p_render_target, const Rect2 &p_screen_rect) GODOT_ARKIT_OVERRIDE;

	// called by delegate (void * because C++ and Obj-C don't always mix, should really change all platform/ios/*.cpp files to .mm)
	void _add_or_update_anchor(GodotARAnchor *p_anchor);
	void _remove_anchor(GodotARAnchor *p_anchor);

	ARKitInterface();
	~ARKitInterface();
};

#endif /* !ARKIT_INTERFACE_H */
