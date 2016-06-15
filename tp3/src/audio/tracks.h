
#ifndef __TRACKS_PLAYER_H__
#define __TRACKS_PLAYER_H__

#include "audioplayer.h"

#define DEFINE_TRACK(name) \
    void audio_track_##name() ; \
    void audio_track_end_##name() ;

DEFINE_TRACK(pacman);
DEFINE_TRACK(spectra0);
DEFINE_TRACK(spectra1);
DEFINE_TRACK(kirby0);
DEFINE_TRACK(kirby1);
DEFINE_TRACK(mario0);
DEFINE_TRACK(mario1);
DEFINE_TRACK(megaman0);
DEFINE_TRACK(megaman1);
DEFINE_TRACK(pokemon_gsc0);
DEFINE_TRACK(pokemon_gsc1);
DEFINE_TRACK(pokemon_rby0);
DEFINE_TRACK(pokemon_rby1);
DEFINE_TRACK(sonic0);
DEFINE_TRACK(sonic1);
DEFINE_TRACK(superfantasy0);
DEFINE_TRACK(superfantasy1);

#undef DEFINE_TRACK
#endif // __TRACKS_PLAYER_H__
