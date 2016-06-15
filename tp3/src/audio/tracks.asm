
%macro INCLUDE_AUDIO 2

global audio_track_%1
global audio_track_end_%1

audio_track_%1:
    incbin %2
audio_track_end_%1:

%endmacro

%macro INCLUDE_AUDIO_CMT 2

global audio_track_%1
global audio_track_end_%1

audio_track_%1:
audio_track_end_%1:

%endmacro

INCLUDE_AUDIO pacman, "audio/tracks/pacman_0.audio"

INCLUDE_AUDIO spectra0, "audio/tracks/spectra_0.audio"
INCLUDE_AUDIO spectra1, "audio/tracks/spectra_1.audio"

INCLUDE_AUDIO kirby0, "audio/tracks/kirby_0.audio"
INCLUDE_AUDIO kirby1, "audio/tracks/kirby_1.audio"

INCLUDE_AUDIO mario0, "audio/tracks/mario_0.audio"
INCLUDE_AUDIO mario1, "audio/tracks/mario_1.audio"

INCLUDE_AUDIO megaman0, "audio/tracks/megaman_0.audio"
INCLUDE_AUDIO megaman1, "audio/tracks/megaman_1.audio"

INCLUDE_AUDIO_CMT pokemon_gsc0, "audio/tracks/pokemon_gsc_0.audio"
INCLUDE_AUDIO_CMT pokemon_gsc1, "audio/tracks/pokemon_gsc_1.audio"

INCLUDE_AUDIO_CMT pokemon_rby0, "audio/tracks/pokemon_rby_0.audio"
INCLUDE_AUDIO_CMT pokemon_rby1, "audio/tracks/pokemon_rby_1.audio"

INCLUDE_AUDIO_CMT sonic0, "audio/tracks/sonic_0.audio"
INCLUDE_AUDIO_CMT sonic1, "audio/tracks/sonic_1.audio"

INCLUDE_AUDIO_CMT superfantasy0, "audio/tracks/superfantasy_0.audio"
INCLUDE_AUDIO_CMT superfantasy1, "audio/tracks/superfantasy_1.audio"
