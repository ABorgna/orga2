
#ifndef __AUDIO_PLAYER_H__
#define __AUDIO_PLAYER_H__

struct audio_note {
    unsigned short freq;
    unsigned short millis;
};

void init_audioplayer();
void play_audio(uint8_t, struct audio_note* file, struct audio_note* end,
                bool loop);
void stop_audio(uint8_t);
void audio_isr();
void test_audio();

#endif // __AUDIO_PLAYER_H__
