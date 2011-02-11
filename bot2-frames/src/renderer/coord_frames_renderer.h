/*
 * coord_frames_renderer.h
 *
 *  Created on: Jan 22, 2011
 *      Author: abachrac
 */
#include <bot_vis/bot_vis.h>
#include <bot_param/param_client.h>

#ifndef COORD_FRAMES_RENDERER_H_
#define COORD_FRAMES_RENDERER_H_

#ifdef __cplusplus
extern "C" {
#endif

  void bot_frames_add_renderer_to_viewer(BotViewer *viewer, int render_priority,
      lcm_t * lcm, BotParam * bot_param);

#ifdef __cplusplus
}
#endif

#endif /* COORD_FRAMES_RENDERER_H_ */
