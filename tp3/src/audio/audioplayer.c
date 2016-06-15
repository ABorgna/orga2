#include "../defines.h"
#include "../i386.h"
#include "../interrupts/pit.h"
#include "../interrupts/pic.h"
#include "speaker.h"

#include "audioplayer.h"
#include "tracks.h"

struct audio_note test_beep[] = { {69,250} };

struct audio_status {
    bool playing;
    bool loop;
    uint8_t curr_cycles;
    uint16_t curr_freq;
    struct audio_note* file_ptr;
    struct audio_note* file_start;
    struct audio_note* file_end;
};

void audio_step(struct audio_status* status);
void update_current_channel();

// 2 background channels, 2 foreground channels
struct audio_status channels[2][2] = {{{0}}};

uint8_t current_channel = 0;
uint32_t audio_step_counter = 0;

void init_audioplayer(){
    // Start the timer at 1kHz
    setupPIT(0,1000);

    // Enable PIT 0 interrupts
    IRQ_clear_mask(0);
}

void play_audio(uint8_t channel, bool foreground,
        struct audio_note* file, struct audio_note* end, bool loop){
    assert(channel < 2);

    struct audio_status *status = &channels[foreground][channel];
    status->playing = 0;

    status->loop = loop;
    status->curr_cycles = 0;
    status->curr_freq = 0;
    status->file_ptr = file;
    status->file_start = file;
    status->file_end = end;

    status->playing = 1;
}

void stop_audio(void) {
    stop_audio_ch(0, true);
    stop_audio_ch(0, false);
    stop_audio_ch(1, true);
    stop_audio_ch(1, false);
}

void stop_audio_ch(uint8_t channel, bool foreground) {
    channels[foreground][channel].playing = 0;

    if(current_channel == channel) {
        nosound();
    }
}

void audio_isr() {
    int i;

    audio_step_counter++;

    for(i=0; i<4; i++) {
        audio_step(((struct audio_status*) channels)+i);
    }

    update_current_channel();

    if(channels[1][current_channel].playing) {
        play_sound(channels[1][current_channel].curr_freq);
    } else if(channels[0][current_channel].playing) {
        play_sound(channels[0][current_channel].curr_freq);
    } else {
        nosound();
    }
}

void audio_step(struct audio_status* status) {
    if(status->playing) {
        if(!status->curr_cycles) {

            if(status->file_ptr == status->file_end){
                // Termino el archivo
                if(status->loop) {
                    status->file_ptr = status->file_start;
                } else {
                    status->playing = 0;
                }
            } else {
                // Cargar siguiente nota
                status->curr_cycles = (*status->file_ptr).millis;

                uint8_t note = (*status->file_ptr).note;
                status->curr_freq = midiNoteToFreq(note);

                status->file_ptr++;
            }

        } else {
            // Seguir con la misma nota
            status->curr_cycles--;
        }
    }
}

void update_current_channel(){
    if(((channels[0][0].playing && channels[0][0].curr_freq) ||
        (channels[1][0].playing && channels[1][0].curr_freq)) &&
       ((channels[0][1].playing && channels[0][1].curr_freq) ||
        (channels[1][1].playing && channels[1][1].curr_freq))) {
        if(!(audio_step_counter & 0x1f)) {
            current_channel = 1 - current_channel;
        }
    } else {
        current_channel = (channels[0][1].playing &&
                           channels[0][1].curr_freq) ||
                          (channels[1][1].playing &&
                           channels[1][1].curr_freq) ? 1 : 0;
    }
}

void play_kirby() {
    play_audio(0, false,
            (struct audio_note*) &audio_track_kirby0,
            (struct audio_note*) &audio_track_end_kirby0,
            true );
    play_audio(1, false,
            (struct audio_note*) &audio_track_kirby1,
            (struct audio_note*) &audio_track_end_kirby1,
            true );
}

void play_mario() {
  //play_audio(0, false,
  //        (struct audio_note*) &audio_track_mario0,
  //        (struct audio_note*) &audio_track_end_mario0,
  //        true );
    stop_audio_ch(0, false);
    play_audio(1, false,
            (struct audio_note*) &audio_track_mario1,
            (struct audio_note*) &audio_track_end_mario1,
            true );
}

void play_megaman() {
    play_audio(0, false,
            (struct audio_note*) &audio_track_megaman0,
            (struct audio_note*) &audio_track_end_megaman0,
            true );
    play_audio(1, false,
            (struct audio_note*) &audio_track_megaman1,
            (struct audio_note*) &audio_track_end_megaman1,
            true );
}

void play_pacman() {
    stop_audio_ch(0, false);
    play_audio(1, false,
            (struct audio_note*) &audio_track_pacman,
            (struct audio_note*) &audio_track_end_pacman,
            true );
}

void play_pokemon_gsc() {
    play_audio(0, false,
            (struct audio_note*) &audio_track_pokemon_gsc0,
            (struct audio_note*) &audio_track_end_pokemon_gsc0,
            true );
    play_audio(1, false,
            (struct audio_note*) &audio_track_pokemon_gsc1,
            (struct audio_note*) &audio_track_end_pokemon_gsc1,
            true );
}

void play_pokemon_rby() {
    play_audio(0, false,
            (struct audio_note*) &audio_track_pokemon_rby0,
            (struct audio_note*) &audio_track_end_pokemon_rby0,
            true );
    play_audio(1, false,
            (struct audio_note*) &audio_track_pokemon_rby1,
            (struct audio_note*) &audio_track_end_pokemon_rby1,
            true );
}

void play_sonic() {
    play_audio(0, false,
            (struct audio_note*) &audio_track_sonic0,
            (struct audio_note*) &audio_track_end_sonic0,
            true );
    play_audio(1, false,
            (struct audio_note*) &audio_track_sonic1,
            (struct audio_note*) &audio_track_end_sonic1,
            true );
}

void play_spectra() {
    play_audio(0, false,
            (struct audio_note*) &audio_track_spectra0,
            (struct audio_note*) &audio_track_end_spectra0,
            true );
    play_audio(1, false,
            (struct audio_note*) &audio_track_spectra1,
            (struct audio_note*) &audio_track_end_spectra1,
            true );
}

void play_superfantasy() {
    play_audio(0, false,
            (struct audio_note*) &audio_track_superfantasy0,
            (struct audio_note*) &audio_track_end_superfantasy0,
            true );
    play_audio(1, false,
            (struct audio_note*) &audio_track_superfantasy1,
            (struct audio_note*) &audio_track_end_superfantasy1,
            true );
}

void play_mov_A() {
//  play_audio(0, true,
//          (struct audio_note*) &audio_track_mov_A,
//          (struct audio_note*) &audio_track_end_mov_A,
//          false );
}

void play_mov_B() {
//  play_audio(0, true,
//          (struct audio_note*) &audio_track_mov_B,
//          (struct audio_note*) &audio_track_end_mov_B,
//          false );
}

uint16_t midiNoteToFreq(uint8_t note) {
    // freq = 440 * 2^((note - 69) / 12)

    // Notes higher than 127 are invalid
    if(!note || note >= 128) {
        return 0;
    }

    // Precomputed 2^(x/12) for 0 <= x < 12
    const uint16_t freqs[128] = {
          8,       8,      9,      9,      10,     10,     11,     12,
          12,     13,     14,     15,      16,     17,     18,     19,
          20,     21,     23,     24,      25,     27,     29,     30,
          32,     34,     36,     38,      41,     43,     46,     48,
          51,     55,     58,     61,      65,     69,     73,     77,
          82,     87,     92,     97,     103,    110,    116,    123,
         130,    138,    146,    155,     164,    174,    184,    195,
         207,    220,    233,    246,     261,    277,    293,    311,
         329,    349,    369,    391,     415,    440,    466,    493,
         523,    554,    587,    622,     659,    698,    739,    783,
         830,    880,    932,    987,    1046,   1108,   1174,   1244,
        1318,   1396,   1479,   1567,    1661,   1760,   1864,   1975,
        2093,   2217,   2349,   2489,    2637,   2793,   2959,   3135,
        3322,   3520,   3729,   3951,    4186,   4434,   4698,   4978,
        5274,   5587,   5919,   6271,    6644,   7040,   7458,   7902,
        8372,   8869,   9397,   9956,   10548,  11175,  11839,  12543
    };

    return freqs[note];
}

