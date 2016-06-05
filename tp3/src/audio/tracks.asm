
%macro INCLUDE_AUDIO 2

global audio_track_%1
global audio_track_end_%1

audio_track_%1:
    incbin %2
audio_track_end_%1:

%endmacro

INCLUDE_AUDIO pacman, "audio/tracks/pacman_0.audio"

INCLUDE_AUDIO spectra0, "audio/tracks/spectra_0.audio"
INCLUDE_AUDIO spectra1, "audio/tracks/spectra_1.audio"

