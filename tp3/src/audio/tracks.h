
#ifndef __TRACKS_PLAYER_H__
#define __TRACKS_PLAYER_H__

#include "audioplayer.h"

#define DEFINE_TRACK(name) \
    void audio_track_##name() ; \
    void audio_track_end_##name() ;

DEFINE_TRACK(pacman);
DEFINE_TRACK(spectra0);
DEFINE_TRACK(spectra1);

#undef DEFINE_TRACK
#endif // __TRACKS_PLAYER_H__
