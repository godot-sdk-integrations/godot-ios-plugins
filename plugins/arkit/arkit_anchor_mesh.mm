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

#include "core/os/os.h"
#include "core/version.h"
#include "scene/resources/surface_tool.h"

#include "core/input/input.h"
#include "servers/rendering/rendering_server_globals.h"

#define GODOT_FOCUS_IN_NOTIFICATION DisplayServer::WINDOW_EVENT_FOCUS_IN
#define GODOT_FOCUS_OUT_NOTIFICATION DisplayServer::WINDOW_EVENT_FOCUS_OUT

#define GODOT_MAKE_THREAD_SAFE ;

#define GODOT_AR_STATE_NOT_TRACKING XRInterface::XR_NOT_TRACKING
#define GODOT_AR_STATE_NORMAL_TRACKING XRInterface::XR_NORMAL_TRACKING
#define GODOT_AR_STATE_EXCESSIVE_MOTION XRInterface::XR_EXCESSIVE_MOTION
#define GODOT_AR_STATE_INSUFFICIENT_FEATURES XRInterface::XR_INSUFFICIENT_FEATURES
#define GODOT_AR_STATE_UNKNOWN_TRACKING XRInterface::XR_UNKNOWN_TRACKING

#import <ARKit/ARKit.h>
#import <UIKit/UIKit.h>

#include <dlfcn.h>

#include "arkit_anchor_mesh.h"

void ARKitAnchorMesh::set_mesh(Ref<Mesh> p_mesh) {
	mesh = p_mesh;
}

Ref<Mesh> ARKitAnchorMesh::get_mesh() const {
	return mesh;
}

void ARKitAnchorMesh::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_mesh", "mesh"), &ARKitAnchorMesh::set_mesh);
	ClassDB::bind_method(D_METHOD("get_mesh"), &ARKitAnchorMesh::get_mesh);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "mesh", PROPERTY_HINT_RESOURCE_TYPE, "Mesh"), "set_mesh", "get_mesh");
}

ARKitAnchorMesh::ARKitAnchorMesh(){
	mesh = NULL;
}

ARKitAnchorMesh::~ARKitAnchorMesh(){

}