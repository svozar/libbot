#include <string.h>

#include <gtk/gtk.h>

#include <bot2-core/bot2-core.h>
#include <bot2-vis/gl_util.h>
#include <bot2-vis/viewer.h>

#include "udp_util.h"
#include "globals.h"

typedef struct {
    BotViewer *viewer;
    lcm_t *lcm;
} state_t;

static int
logplayer_remote_on_key_press(BotViewer *viewer, BotEventHandler *ehandler,
        const GdkEventKey *event)
{
    int keyval = event->keyval;

    switch (keyval)
    {
    case 'P':
    case 'p':
        udp_send_string("127.0.0.1", 53261, "PLAYPAUSETOGGLE");
        break;
    case 'N':
    case 'n':
        udp_send_string("127.0.0.1", 53261, "STEP");
        break;
    case '=':
    case '+':
        udp_send_string("127.0.0.1", 53261, "FASTER");
        break;
    case '_':
    case '-':
        udp_send_string("127.0.0.1", 53261, "SLOWER");
        break;
    case '[':
        udp_send_string("127.0.0.1", 53261, "BACK5");
        break;
    case ']':
        udp_send_string("127.0.0.1", 53261, "FORWARD5");
        break;
    default:
        return 0;
    }

    return 1;
}

/////////////////////////////////////////////////////////////

void setup_view_menu(BotViewer *viewer);

void setup_renderer_grid(BotViewer *viewer, int render_priority);
void setup_renderer_lcmgl(BotViewer *viewer, int render_priority);

int main(int argc, char *argv[])
{
    gtk_init(&argc, &argv);
    glutInit(&argc, argv);
    g_thread_init(NULL);

    setlinebuf(stdout);

    state_t app;
    memset(&app, 0, sizeof(app));

    BotViewer *viewer = bot_viewer_new("Viewer");
    app.viewer = viewer;
    app.lcm = globals_get_lcm();
    bot_glib_mainloop_attach_lcm(app.lcm);

    setup_view_menu(viewer);

    // setup renderers
    setup_renderer_grid(viewer, 1);
    setup_renderer_lcmgl(viewer, 0);

    // logplayer controls
    BotEventHandler *ehandler = (BotEventHandler*) calloc(1, sizeof(BotEventHandler));
    ehandler->name = "LogPlayer Remote";
    ehandler->enabled = 1;
    ehandler->key_press = logplayer_remote_on_key_press;
    bot_viewer_add_event_handler(viewer, ehandler, 0);

    // load saved preferences
    char *fname = g_build_filename(g_get_user_config_dir(), 
            ".bot-lcmgl-viewerrc", NULL);
    bot_viewer_load_preferences(viewer, fname);

    // run the main loop
    gtk_main();

    // save any changed preferences
    bot_viewer_save_preferences(viewer, fname);
    free(fname);

    // cleanup
    bot_viewer_unref(viewer);
}