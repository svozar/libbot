#ifndef _BOT_LCMGL_DECODE_H
#define _BOT_LCMGL_DECODE_H

#include <inttypes.h>

/**
 * SECTION:lcmgl_decode
 * @title: LCMGL decoding
 * @short_description: Executing OpenGL commands received via LCMGL
 * @include: bot2-vis/bot2-vis.h
 *
 * TODO
 *
 * Linking: -lbot2-vis
 */

#ifdef __cplusplus
extern "C" {
#endif

/**
 * bot_lcmgl_decode:
 *
 * Decodes a block of LCMGL data, and executes the OpenGL commands with 
 * the current OpenGL context.
 */
void bot_lcmgl_decode(uint8_t *data, int datalen);

#ifdef __cplusplus
}
#endif

#endif