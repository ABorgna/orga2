#include "../defines.h"
#include "../i386.h"
#include "../interrupts/pit.h"
#include "../interrupts/pic.h"
#include "speaker.h"

#include "audioplayer.h"
#include "tracks.h"

struct audio_note test_beep[] = { {440,1000}, {440, 1000} };

struct audio_status {
    bool playing;
    bool loop;
    uint16_t curr_cycles;
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

void stop_audio(uint8_t channel) {
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
                channels[channel].curr_freq = (*channels[channel].file_ptr).freq;

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
        if(!(audio_step_counter & 0xf)) {
            current_channel = 1 - current_channel;
        }
    } else {
        current_channel = channels[1].playing ? 1 : 0;
    }
}

void test_audio() {
    play_audio(1,
            (struct audio_note*) &audio_track_pacman,
            (struct audio_note*) &audio_track_end_pacman,
            true );
    play_audio(0,
            test_beep,
            test_beep+ARRAY_SIZE(test_beep),
            true );
}

