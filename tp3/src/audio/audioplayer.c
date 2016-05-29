#include "../defines.h"
#include "../i386.h"
#include "speaker.h"

#include "audioplayer.h"
#include "tracks.h"

bool audioPlaying = 0;
bool loopAudio = 0;
short audioCycles;
struct audio_note* audioFilePtr;
struct audio_note* audioFileStart;
struct audio_note* audioFileEnd;

void play_audio(struct audio_note* file, struct audio_note* end, bool loop){
    audioPlaying = 0;

    audioFilePtr = file;
    audioFileStart = file;
    audioFileEnd = end;
    loopAudio = loop;

    audioPlaying = 1;
}

void stop_audio() {
    audioPlaying = 0;
    nosound();
}

void audio_isr() {
    if(audioPlaying) {
        if(!audioCycles) {
            if(audioFilePtr == audioFileEnd){
                if(loopAudio) {
                    audioFilePtr = audioFileStart;
                } else {
                    stop_audio();
                }
            } else {
                //breakpoint();

                play_sound((*audioFilePtr).freq);
                audioCycles = (*audioFilePtr).cycles;

                audioFilePtr++;
            }
        } else {
            audioCycles--;
        }
    }
}

void test_audio() {
    play_audio(
            (struct audio_note*) &audio_track_pacman,
            (struct audio_note*) &audio_track_end_pacman,
            true );
}

