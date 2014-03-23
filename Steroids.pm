module Steroids;
use NativeCall;
constant PATH = './sdlwrapper';

class Texture is repr('CStruct') {
    has OpaquePointer $.tex;
    has int32 $.w;
    has int32 $.h;
}

sub game_init(int32, int32) returns OpaquePointer                 is native(PATH) { * } 
sub game_set_keypressed_cb(OpaquePointer, &cb(int32))             is native(PATH) { * }
sub game_set_update_cb(OpaquePointer, &cb())                      is native(PATH) { * }
sub game_set_draw_cb(OpaquePointer, &cb())                        is native(PATH) { * }
sub game_is_pressed(int32) returns int32                          is native(PATH) { * }
sub game_is_pressed_name(Str) returns int32                       is native(PATH) { * }
sub game_is_running(OpaquePointer) returns int32                  is native(PATH) { * }
sub game_loop(OpaquePointer)                                      is native(PATH) { * }
sub game_quit(OpaquePointer)                                      is native(PATH) { * }
sub game_free(OpaquePointer)                                      is native(PATH) { * }
sub game_load_texture(OpaquePointer, Str) returns Texture         is native(PATH) { * }
sub game_renderer_clear(OpaquePointer)                            is native(PATH) { * }
sub game_draw_texture(OpaquePointer, Texture, int32, int32)       is native(PATH) { * }
sub game_renderer_present(OpaquePointer)                          is native(PATH) { * }

class Game {
    has $.width;
    has $.height;
    has Mu $!game;
    has %!assets;
    has @!entities;

    class Entity {
        has $.x is rw;
        has $.y is rw;
        has $.velocity = [0, 0];
        has $.gravity is rw;
        has Texture $.tex handles <w h>;
        has @.events;

        method when (&condition, &action) {
            @!events.push: [&condition, &action];
        }
    }

    method create { ... }
    method update { ... }
    method keypressed($k) { }

    submethod BUILD(:$!width, :$!height) {
        $!width //= 1024;
        $!height //= 768;
        $!game := game_init($!width, $!height);
        sub key_cb(int32 $k) {
            self.keypressed($k)
        }
        sub update_cb {
            self.physics();
            self.events();
            self.update();
        }
        sub draw_cb {
            self.draw();
        }
        game_set_keypressed_cb($!game, &key_cb);
        game_set_update_cb($!game, &update_cb);
        game_set_draw_cb($!game, &draw_cb);
    }

    multi method is_pressed(int32 $key) {
        game_is_pressed($key);
    }

    multi method is_pressed(Str $key) {
        game_is_pressed_name($key);
    }

    method start {
        self.create();
        game_loop($!game);
        game_free($!game);
    }

    method quit { game_quit($!game) }

    method load_bitmap(Str $name, Str $path) {
        my $tex = game_load_texture($!game, $path);
        %!assets{$name} = $tex;
        return $tex;
    }

    method add_sprite(Str $asset, Int $x, Int $y) {
        unless %!assets{$asset}:exists {
            die "No such asset loaded: $asset"
        }
        my $d = Entity.new(:$x, :$y, :tex(%!assets{$asset}));
        @!entities.push: $d;
        return $d;
    }

    method remove_sprite(Entity $d) {
        @!entities.=grep(* !=== $d);
    }

    method events {
        for @!entities -> $ent {
            for $ent.events -> $ev {
                if $ev[0].($ent) {
                    $ev[1].($ent)
                }
            }
        }
    }

    method physics {
        for @!entities {
            if $_.gravity {
                $_.velocity[1] += 1
            }
            $_.x += $_.velocity[0];
            $_.y += $_.velocity[1];
        }
    }

    method draw {
        game_renderer_clear($!game);
        for @!entities {
            game_draw_texture($!game, $_.tex, $_.x, $_.y);
        }
        game_renderer_present($!game);
    }
}
