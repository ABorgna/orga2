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

void audio_step(uint8_t channel);
void update_current_channel();

struct audio_status channels[2] = {{0},{0}};
uint8_t current_channel = 0;
uint32_t audio_step_counter = 0;

void init_audioplayer(){
    // Start the timer at 1kHz
    setupPIT(0,1000);

    // Enable PIT 0 interrupts
    IRQ_clear_mask(0);
}

void play_audio(uint8_t channel,
        struct audio_note* file, struct audio_note* end, bool loop){
    channels[channel].playing = 0;

    channels[channel].loop = loop;
    channels[channel].curr_cycles = 0;
    channels[channel].curr_freq = 0;
    channels[channel].file_ptr = file;
    channels[channel].file_start = file;
    channels[channel].file_end = end;

    channels[channel].playing = 1;
}

void stop_audio(void) {
    stop_audio_ch(0);
    stop_audio_ch(1);
}

void stop_audio_ch(uint8_t channel) {
    channels[channel].playing = 0;

    if(current_channel == channel) {
        nosound();
    }
}

void audio_isr() {
    audio_step_counter++;

    audio_step(0);
    audio_step(1);

    update_current_channel();

    if(channels[current_channel].playing) {
        play_sound(channels[current_channel].curr_freq);
    } else {
        nosound();
    }
}

void audio_step(uint8_t channel) {
    if(channels[channel].playing) {
        if(!channels[channel].curr_cycles) {

            if(channels[channel].file_ptr == channels[channel].file_end){
                // Termino el archivo
                if(channels[channel].loop) {
                    channels[channel].file_ptr = channels[channel].file_start;
                } else {
                    channels[channel].playing = 0;
                }
            } else {
                // Cargar siguiente nota
                channels[channel].curr_cycles = (*channels[channel].file_ptr).millis;

                uint8_t note = (*channels[channel].file_ptr).note;
                channels[channel].curr_freq = midiNoteToFreq(note);

                channels[channel].file_ptr++;
            }

        } else {
            // Seguir con la misma nota
            channels[channel].curr_cycles--;
        }
    }
}

void update_current_channel(){
    if(channels[0].playing && channels[1].playing) {
        if(!(audio_step_counter & 0x3)) {
            current_channel = 1 - current_channel;
        }
    } else {
        current_channel = channels[1].playing ? 1 : 0;
    }
}

void play_spectra() {
    play_audio(0,
            (struct audio_note*) &audio_track_spectra0,
            (struct audio_note*) &audio_track_end_spectra0,
            true );
    play_audio(1,
            (struct audio_note*) &audio_track_spectra1,
            (struct audio_note*) &audio_track_end_spectra1,
            true );
}

void play_pacman() {
    stop_audio_ch(0);
    play_audio(1,
            (struct audio_note*) &audio_track_pacman,
            (struct audio_note*) &audio_track_end_pacman,
            true );
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

