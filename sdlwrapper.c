#include <SDL.h>
#include <stdlib.h>

typedef struct {
    SDL_Texture *tex;
    int w, h;
} Texture;

typedef struct {
    SDL_Window *window;
    SDL_Renderer *renderer;
    void (*keypressed_cb)(int);
    void (*update_cb)(void);
    void (*draw_cb)(void);
    int running;
    int events_waiting;
    int frames_skipped;
} Game;

int timer_cb(int interval, void *arg)
{
    SDL_Event event;
    Game *g = (Game *)arg;
    if (g->events_waiting <= 3) {
        event.type = SDL_USEREVENT;
        SDL_PushEvent(&event);
        g->events_waiting++;
    } else {
        g->frames_skipped++;
    }
    return interval;
}

extern Game *
game_init(int width, int height)
{
    SDL_Init(SDL_INIT_EVERYTHING);

    Game *game = malloc(sizeof(Game));
    game->window = SDL_CreateWindow("Steroids", -1, -1, width, height, SDL_WINDOW_SHOWN);
    game->renderer = SDL_CreateRenderer(game->window, -1,
                                        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    game->running = 1;
    game->keypressed_cb = NULL;
    game->update_cb = NULL;
    game->draw_cb = NULL;
    game->events_waiting = 0;
    game->frames_skipped = 0;

    SDL_AddTimer(16, (SDL_TimerCallback)timer_cb, game);

    return game;
}

extern void
game_quit(Game *game)
{
    game->running = 0;
}

extern void
game_set_keypressed_cb(Game *game, void (*keypressed_cb)(int))
{
    game->keypressed_cb = keypressed_cb;
}

extern void
game_set_update_cb(Game *game, void (*update_cb)(void))
{
    game->update_cb = update_cb;
}

extern void
game_set_draw_cb(Game *game, void (*draw_cb)(void))
{
    game->draw_cb = draw_cb;
}

extern SDL_Renderer *
game_get_renderer(Game *game)
{
    return game->renderer;
}

extern Texture *
game_load_texture(Game *game, const char *path)
{
    //TODO Handle errors
    Texture *ret = malloc(sizeof(Texture));
    SDL_Surface *bmp = SDL_LoadBMP(path);
    if (!bmp) {
        printf("%s\n", SDL_GetError());
    }
    ret->tex = SDL_CreateTextureFromSurface(game->renderer, bmp);
    ret->w = bmp->w;
    ret->h = bmp->h;
    SDL_FreeSurface(bmp);
    return ret;
}

extern void
game_renderer_clear(Game *game)
{
    SDL_RenderClear(game->renderer);
}

extern void
game_draw_texture(Game *game, Texture *tex, int x, int y)
{
    SDL_Rect dest;
    dest.w = tex->w;
    dest.h = tex->h;
    dest.x = x;
    dest.y = y;
    SDL_RenderCopy(game->renderer, tex->tex, NULL, &dest);
}

extern void game_renderer_present(Game *game) {
    SDL_RenderPresent(game->renderer);
}

extern int
game_is_pressed(int idx)
{
    const Uint8 *state = SDL_GetKeyboardState(NULL);

    return !!state[idx];
}

extern int
game_is_pressed_name(const char *name)
{
    SDL_Keycode key = SDL_GetKeyFromName(name);
    int idx = SDL_GetScancodeFromKey(key);
    return game_is_pressed(idx);
}

extern int
game_is_running(Game *game)
{
    return game->running;
}

extern void
game_loop(Game *game)
{
    SDL_Event event;
    Uint32 ticks, totalticks;
    totalticks = 0;
    Uint32 maxticks = 0;
    int iterations = 0;
    while (game->running) {
        SDL_WaitEvent(&event);
        switch (event.type) {
        case SDL_USEREVENT: // timer
            game->events_waiting--;
            ticks = SDL_GetTicks();
            game->update_cb();
            ticks = SDL_GetTicks() - ticks;
            totalticks += ticks;
            if (ticks > maxticks) {
                maxticks = ticks;
            }
            iterations++;
            //printf("Update took %d ticks\n", ticks);
            game->draw_cb();
            break;
        case SDL_KEYDOWN:
            if (game->keypressed_cb) game->keypressed_cb(event.key.keysym.sym);
            break;
        //case SDL_KEYUP:
        case SDL_QUIT:
            game->running = 0;
            break;
        }
    }
    printf("%d ticks in %d iterations\n", totalticks, iterations);
    printf("That's %f ticks per update\n", (double)totalticks / iterations);
    printf("Longest frame took %d ticks\n", maxticks);
}

extern void
game_free(Game *game)
{
    printf("%d frames skipped\n", game->frames_skipped);
    SDL_DestroyRenderer(game->renderer);
    SDL_DestroyWindow(game->window);
    SDL_Quit();
    free(game);
}
