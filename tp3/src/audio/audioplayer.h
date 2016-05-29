
#ifndef __AUDIO_PLAYER_H__
#define __AUDIO_PLAYER_H__

struct audio_note {
    unsigned short freq;
    unsigned short cycles;
};

void play_audio(struct audio_note* file, struct audio_note* end, bool loop);
void stop_audio();
void audio_isr();
void test_audio();

#endif // __AUDIO_PLAYER_H__
