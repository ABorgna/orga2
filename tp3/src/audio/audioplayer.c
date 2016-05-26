#include "../defines.h"
#include "../i386.h"
#include "speaker.h"

#include "audioplayer.h"

bool audioPlaying = 0;
short* audioFile;
short* audioFileEnd;

short test_audio_file[4] = {512, 1024, 2048, 4096};

void play_audio(short* file, short* end){
    audioPlaying = 0;
    audioFile = file;
    audioFileEnd = end;
    audioPlaying = 1;
}

void audio_isr() {
    if(audioPlaying) {
        if(audioFile == audioFileEnd){
            nosound();
            audioPlaying = 0;
        } else {
            play_sound(*audioFile);
        }
    }
}

void test_audio() {
    play_audio(test_audio_file, test_audio_file+4);
}

