/*************************************************************************/
/*  game_center_saved_game.h                                             */
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

#ifndef GAME_CENTER_SAVED_GAME_H
#define GAME_CENTER_SAVED_GAME_H

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/object/ref_counted.h"
#else
#include "core/reference.h"
typedef Reference RefCounted;
#endif

@class GKSavedGame;

class GameCenterSavedGame : public RefCounted {

	GDCLASS(GameCenterSavedGame, RefCounted);

    static void _bind_methods();

    GKSavedGame *saved_game;

public:
    String get_name() const;
    int64_t get_modification_date() const;
    String get_device_name() const;
    bool is_current_device() const;

    GKSavedGame *get_saved_game() const;

    void load_data();

    virtual String to_string() override;

    GameCenterSavedGame(GKSavedGame *saved_game);
    ~GameCenterSavedGame();
};

#endif // GAME_CENTER_SAVED_GAME_H