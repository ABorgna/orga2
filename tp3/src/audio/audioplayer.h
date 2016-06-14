
#ifndef __AUDIO_PLAYER_H__
#define __AUDIO_PLAYER_H__

struct audio_note {
    uint8_t note;
    uint8_t millis;
};

void init_audioplayer();
void play_audio(uint8_t channel, bool foreground,
                struct audio_note* file, struct audio_note* end,
                bool loop);
void stop_audio();
void stop_audio_ch(uint8_t channel, bool foreground);
void audio_isr();
uint16_t midiNoteToFreq(uint8_t note);

void play_kirby();
void play_mario();
void play_megaman();
void play_pacman();
void play_pokemon_gsc();
void play_pokemon_rby();
void play_sonic();
void play_spectra();
void play_superfantasy();

void play_mov_A();
void play_mov_B();

#endif // __AUDIO_PLAYER_H__
