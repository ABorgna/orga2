
#ifndef __AUDIO_PLAYER_H__
#define __AUDIO_PLAYER_H__

struct audio_note {
    uint8_t note;
    uint8_t millis;
};

void init_audioplayer();
void play_audio(uint8_t channel,
                struct audio_note* file, struct audio_note* end,
                bool loop);
void stop_audio(uint8_t channel);
void audio_isr();
void test_audio();
uint16_t midiNoteToFreq(uint8_t note);

#endif // __AUDIO_PLAYER_H__
