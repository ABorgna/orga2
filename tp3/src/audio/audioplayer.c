#include "../defines.h"
#include "../i386.h"
#include "speaker.h"

#include "audioplayer.h"

struct audio_note {
    short freq;
    short cycles;
};

bool audioPlaying = 0;
struct audio_note* audioFile;
struct audio_note* audioFileEnd;
short audioCycles;

struct audio_note test_audio_file[] = {
    {880, 4096},
    {512, 1024},
    {1024, 1024},
    {2048, 1024},
    {4096, 1024}
};

void play_audio(struct audio_note* file, struct audio_note* end){
    audioPlaying = 0;
    audioFile = file;
    audioFileEnd = end;
    audioPlaying = 1;
}

void audio_isr() {
    if(audioPlaying) {
        if(!audioCycles) {
            if(audioFile == audioFileEnd){
                //nosound();
                //audioPlaying = 0;
                //breakpoint();
                //breakpoint();
                test_audio();
            } else {
                //breakpoint();
                play_sound((*audioFile).freq);
                audioCycles = (*audioFile).cycles;

                audioFile++;
            }
        } else {
            audioCycles--;
        }
    }
}

void test_audio() {
    play_audio(test_audio_file, test_audio_file+4);
}

