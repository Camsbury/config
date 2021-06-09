#include "ergodox_ez.h"
#include "debug.h"
#include "action_layer.h"
#include "version.h"
#include "keymap_german.h"
#include "keymap_nordic.h"


#define CHROME_INSPECT_M LGUI(LSFT(KC_C))
#define CHROME_INSPECT_L LCTL(LSFT(KC_J))

enum custom_keycodes {
  PLACEHOLDER = SAFE_RANGE, // can always be here
  EPRM,
  VRSN,
  RGB_SLD,
  /* EXAMPLE, */
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

  // MAIN LAYER
  [0] = LAYOUT_ergodox(
      //LEFT HAND
      KC_NO,             KC_PGDOWN,      KC_PGUP,           KC_MEDIA_PREV_TRACK, KC_MEDIA_NEXT_TRACK, KC_MEDIA_PLAY_PAUSE, LCTL(KC_Q),
      KC_TAB,            KC_Q,           KC_W,              KC_F,                KC_P,                KC_G,                LGUI(KC_X),
      LT(1,KC_LBRACKET), KC_A,           KC_R,              KC_S,                KC_T,                KC_D,
      KC_LSPO,           KC_Z,           KC_X,              KC_C,                KC_V,                KC_B,                KC_CAPSLOCK,
      ALL_T(KC_NO),      KC_LALT,        LSFT(LALT(KC_NO)), MEH_T(KC_NO),        KC_LGUI,

                                                                                 KC_NO,               KC_NO,
                                                                                                                           KC_NO,
                                                                                 KC_SPACE,            LT(2,KC_ESCAPE),     CTL_T(KC_NO),


      //RIGHT HAND
      KC_NO,          KC_AUDIO_MUTE,  KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN,   LGUI(KC_KP_PLUS),    LGUI(KC_MINUS),      KC_NO,
      LGUI(KC_SPACE), KC_J,           KC_L,            KC_U,                KC_Y,                KC_COLN,             KC_DELETE,
                      KC_H,           KC_N,            KC_E,                KC_I,                KC_O,                LT(1,KC_RBRACKET),
      KC_NO,          KC_K,           KC_M,            KC_COMMA,            KC_DOT,              KC_SLASH,            KC_RSPC,
                                      KC_LGUI,         MEH_T(KC_NO),        LSFT(LALT(KC_NO)),   KC_LALT,             ALL_T(KC_NO),

      KC_NO,
                      KC_NO,          KC_NO,
      CTL_T(KC_NO),   LT(2,KC_ENTER), KC_BSPACE),

  // SYMBOL LAYER
  [1] = LAYOUT_ergodox(
      //LEFT HAND
      KC_NO,   KC_NO,   KC_NO,       KC_NO,    KC_NO,    KC_NO,     KC_NO,
      KC_NO,   KC_DLR,  KC_CIRC,     KC_HASH,  KC_UNDS,  KC_NO,     KC_NO,
      KC_TRNS, KC_PLUS, KC_ASTERISK, KC_EQUAL, KC_MINUS, KC_QUES,
      KC_LCBR, KC_LEFT, KC_DOWN,     KC_UP,    KC_RIGHT, KC_NO,     KC_NO,
      KC_NO,   KC_NO,   KC_NO,       KC_NO,    KC_NO,

                                               KC_NO,    KC_NO,
                                                                    KC_NO,
                                               KC_NO,    KC_NO,     KC_NO,


      //RIGHT HAND
      KC_NO,   KC_NO,   KC_NO,       KC_NO,    KC_NO,    KC_NO,     KC_NO,
      KC_NO,   KC_NO,   KC_AT,       KC_PERC,  KC_PIPE,  KC_SCOLON, KC_NO,
               KC_EXLM, KC_QUOTE,    KC_DQUO,  KC_GRAVE, KC_TILD,   KC_TRNS,
      KC_NO,   KC_NO,   KC_AMPR,     KC_LABK,  KC_RABK,  KC_BSLASH, KC_RCBR,
                        KC_NO,       KC_NO,    KC_NO,    KC_NO,     KC_NO,

      KC_NO,
               KC_NO,   KC_NO,
      KC_NO,   TO(3),   KC_NO),

  // NUMBER LAYER
  [2] = LAYOUT_ergodox(
      //LEFT HAND
      CHROME_INSPECT_L, KC_F1,              KC_F2,            KC_F3,            KC_F4,            KC_F5,            CHROME_INSPECT_M,
      KC_NO,            LALT(KC_1),         LALT(KC_2),       LALT(KC_3),       LALT(KC_4),       LALT(KC_5),       KC_NO,
      KC_NO,            KC_1,               KC_2,             KC_3,             KC_4,             KC_5,
      KC_LCTL,          LSFT(LALT(KC_1)),   LSFT(LALT(KC_2)), LSFT(LALT(KC_3)), LSFT(LALT(KC_4)), LSFT(LALT(KC_5)), KC_NO,
      KC_NO,            KC_LALT,            KC_NO,            KC_NO,            KC_NO,

                                                                                KC_NO,            KC_NO,
                                                                                                                    KC_NO,
                                                                                KC_NO,            KC_TRNS,          KC_NO,


      //RIGHT HAND
      KC_NO,            KC_F6,              KC_F7,            KC_F8,            KC_F9,            KC_F10,           KC_F11,
      KC_NO,            LALT(KC_6),         LALT(KC_7),       LALT(KC_8),       LALT(KC_9),       LALT(KC_0),       KC_F12,
                        KC_6,               KC_7,             KC_8,             KC_9,             KC_0,             KC_NO,
      KC_NO,            LSFT(LALT(KC_6)),   LSFT(LALT(KC_7)), LSFT(LALT(KC_8)), LSFT(LALT(KC_9)), LSFT(LALT(KC_0)), KC_LCTL,
                                            KC_NO,            KC_NO,            KC_NO,            KC_LALT,          KC_NO,

      KC_NO,
                        KC_NO,              KC_NO,
      KC_NO,            KC_TRNS,            KC_NO),

  /* // BRAID LAYER */
  [3] = LAYOUT_ergodox(
      //LEFT HAND
      TO(0), TO(3),   TO(4),   KC_MEDIA_PREV_TRACK, KC_MEDIA_NEXT_TRACK, KC_MEDIA_PLAY_PAUSE, KC_NO,
      TO(5), KC_NO,   KC_NO,   KC_NO,               KC_NO,               KC_NO,               KC_NO,
      KC_NO, KC_LEFT, KC_DOWN, KC_UP,               KC_RIGHT,            KC_NO,
      KC_NO, KC_NO,   KC_NO,   KC_NO,               KC_NO,               KC_NO,               KC_NO,
      KC_NO, KC_NO,   KC_NO,   KC_NO,               KC_NO,

                                                    KC_NO,               KC_NO,
                                                                                              KC_NO,
                                                    KC_NO,               KC_TRNS,             KC_NO,


      //RIGHT HAND
      KC_NO, KC_AUDIO_MUTE, KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN, KC_NO, KC_NO, KC_NO,
      KC_NO, KC_NO,         KC_NO,           KC_NO,             KC_NO, KC_NO, KC_NO,
             KC_LSFT,       KC_NO,           KC_NO,             KC_NO, KC_NO, KC_NO,
      KC_NO, KC_NO,         KC_NO,           KC_NO,             KC_NO, KC_NO, KC_NO,
                            KC_NO,           KC_NO,             KC_NO, KC_NO, KC_NO,

      KC_NO,
             KC_NO,         KC_NO,
      KC_NO, KC_TRNS,       KC_SPACE),

  /* // CUPHEAD LAYER */
  [4] = LAYOUT_ergodox(
      //LEFT HAND
      TO(0), TO(3),   TO(4),   KC_MEDIA_PREV_TRACK, KC_MEDIA_NEXT_TRACK, KC_MEDIA_PLAY_PAUSE, KC_NO,
      KC_NO, KC_NO,   KC_NO,   KC_NO,               KC_NO,               KC_NO,               KC_NO,
      KC_NO, KC_LEFT, KC_DOWN, KC_UP,               KC_RIGHT,            KC_NO,
      KC_NO, KC_NO,   KC_NO,   KC_NO,               KC_NO,               KC_NO,               KC_NO,
      KC_NO, KC_NO,   KC_NO,   KC_NO,               KC_NO,

                                                    KC_NO,               KC_NO,
                                                                                              KC_NO,
                                                    KC_NO,               KC_ESCAPE,           KC_NO,


      //RIGHT HAND
      KC_NO, KC_AUDIO_MUTE, KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN, KC_NO,   KC_NO, KC_NO,
      KC_NO, KC_NO,         KC_NO,           KC_NO,             KC_NO,   KC_NO, KC_NO,
             KC_NO,         KC_X,            KC_V,              KC_LSFT, KC_C,  KC_TAB,
      KC_NO, KC_NO,         KC_NO,           KC_NO,             KC_NO,   KC_NO, KC_NO,
                            KC_NO,           KC_NO,             KC_NO,   KC_NO, KC_NO,

      KC_NO,
             KC_NO,         KC_NO,
      KC_NO, KC_TRNS,       KC_Z),

  /* // SC2 LAYER */
  /* [3] = LAYOUT_ergodox( */
  /*     //BATTLE HAND */
  /*     KC_ESCAPE,      KC_1,           KC_2,           KC_3,                KC_4,             KC_5,           KC_6, */
  /*     KC_TAB,         KC_Q,           KC_W,           KC_F,                KC_P,             KC_G,           KC_HOME, */
  /*     KC_LBRACKET,    KC_A,           KC_R,           KC_S,                KC_T,             KC_D, */
  /*     KC_RBRACKET,    KC_Z,           KC_X,           KC_C,                KC_V,             KC_B,           KC_QUOTE, */
  /*     MEH_T(KC_NO),   KC_7,           KC_8,           KC_9,                KC_0, */

  /*                                                                          LCA_T(KC_NO),     C_S_T(KC_NO), */
  /*                                                                                                            LSFT(LALT_T(KC_NO)), */
  /*                                                                          LCTL_T(KC_NO),    LALT_T(KC_NO),  LSFT_T(KC_NO), */


  /*     //AUXILIARY HAND */
  /*     KC_NO,          KC_AUDIO_MUTE,  KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN,  LGUI(KC_PLUS), LGUI(KC_MINUS), TO(0), */
  /*     LGUI(KC_SPACE), KC_J,           KC_L,            KC_U,               KC_Y,             KC_COLN,        KC_DELETE, */
  /*                     KC_H,           KC_N,            KC_E,               KC_I,             KC_O,           KC_RBRACKET, */
  /*     KC_NO,          KC_K,           KC_M,            KC_COMMA,           KC_DOT,           KC_SLASH,       KC_RSPC, */
  /*                                     KC_LGUI,         KC_LALT,            MEH_T(KC_NO),     ALL_T(KC_NO),   KC_NO, */

  /*     KC_NO, */
  /*                     KC_NO,          KC_NO, */
  /*     KC_NO,          KC_ENTER,       KC_BSPACE), */

  /* // WC3 LAYER */
  [5] = LAYOUT_ergodox(
      //BATTLE HAND
      CTL_T(KC_NO),      KC_1,           KC_2,            KC_3,               KC_4,             KC_5,            KC_6,
      KC_TAB,            KC_Q,           KC_W,            KC_F,               KC_P,             KC_G,            KC_7,
      LT(1,KC_LBRACKET), KC_A,           KC_R,            KC_S,               KC_T,             KC_D,
      KC_LSPO,           KC_Z,           KC_X,            KC_C,               KC_V,             KC_B,            KC_8,
      KC_F1,             KC_F2,          KC_F3,           KC_LALT,            CTL_T(KC_NO),

                                                                              KC_9,             KC_0,
                                                                                                                 KC_NO,
                                                                              KC_SPACE,         LT(6,KC_ESCAPE), KC_LSFT,


      //AUXILIARY HAND
      KC_NO,             KC_AUDIO_MUTE,  KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN,  LGUI(KC_PLUS),    LGUI(KC_MINUS),  TO(0),
      LGUI(KC_SPACE),    KC_J,           KC_L,            KC_U,               KC_Y,             KC_COLN,         KC_DELETE,
                         KC_H,           KC_N,            KC_E,               KC_I,             KC_O,            LT(1,KC_RBRACKET),
      KC_NO,             KC_K,           KC_M,            KC_COMMA,           KC_DOT,           KC_SLASH,        KC_RSPC,
                                         KC_LGUI,         KC_LALT,            MEH_T(KC_NO),     ALL_T(KC_NO),    KC_NO,

      KC_NO,
                         KC_NO,          KC_NO,
      CTL_T(KC_NO),      LT(2,KC_ENTER), KC_BSPACE),

  /* // WC3 LAYER 2 */
  [6] = LAYOUT_ergodox(
      //LEFT HAND
      KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
      KC_NO, KC_NO, KC_NO, KC_P7, KC_P8, KC_P9, KC_NO,
      KC_NO, KC_NO, KC_NO, KC_P4, KC_P5, KC_P6,
      KC_NO, KC_NO, KC_NO, KC_P1, KC_P2, KC_P3, KC_NO,
      KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,

                                  KC_NO, KC_NO,
                                                KC_NO,
                                  KC_NO, KC_NO, KC_NO,


      KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
      KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
             KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
      KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
                    KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,

      KC_NO,
             KC_NO, KC_NO,
      KC_NO, KC_NO, KC_NO),

  // NO LAYER
  /* [#] = LAYOUT_ergodox( */
  /*     //LEFT HAND */
  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */

  /*                                 KC_NO, KC_NO, */
  /*                                               KC_NO, */
  /*                                 KC_NO, KC_NO, KC_NO, */


  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*            KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*     KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */
  /*                   KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, */

  /*     KC_NO, */
  /*            KC_NO, KC_NO, */
  /*     KC_NO, KC_NO, KC_NO, */

};

const uint16_t PROGMEM fn_actions[] = {
  [1] = ACTION_LAYER_TAP_TOGGLE(1)
};

// leaving this in place for compatibilty with old keymaps cloned and re-compiled.
const macro_t *action_get_macro(keyrecord_t *record, uint8_t id, uint8_t opt)
{
      switch(id) {
        case 0:
        if (record->event.pressed) {
          SEND_STRING (QMK_KEYBOARD "/" QMK_KEYMAP " @ " QMK_VERSION);
        }
        break;
      }
    return MACRO_NONE;
};

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
    // dynamically generate these.
    /* case EXAMPLE: */
    /*   if (record->event.pressed) { */
    /*       SEND_STRING("  ce"); */
    /*   } */
    /*   return false; */
    /*   break; */
    case EPRM:
      if (record->event.pressed) {
        eeconfig_init();
      }
      return false;
      break;
    /* case VRSN: */
    /*   if (record->event.pressed) { */
    /*     SEND_STRING (QMK_KEYBOARD "/" QMK_KEYMAP " @ " QMK_VERSION); */
    /*   } */
    /*   return false; */
    /*   break; */
    /* case RGB_SLD: */
    /*   if (record->event.pressed) { */
    /*     rgblight_mode(1); */
    /*   } */
    /*   return false; */
    /*   break; */

  }
  return true;
}

uint32_t layer_state_set_user(uint32_t state) {

    uint8_t layer = biton32(state);

    ergodox_board_led_off();
    ergodox_right_led_1_off();
    ergodox_right_led_2_off();
    ergodox_right_led_3_off();
    switch (layer) {
      case 0:
        break;
      case 1:
        ergodox_right_led_1_on();
        break;
      case 2:
        ergodox_right_led_2_on();
        break;
      case 3:
        ergodox_right_led_3_on();
        break;
      case 4:
        ergodox_right_led_1_on();
        ergodox_right_led_2_on();
        break;
      case 5:
        ergodox_right_led_1_on();
        ergodox_right_led_3_on();
        break;
      case 6:
        ergodox_right_led_2_on();
        ergodox_right_led_3_on();
        break;
      case 7:
        ergodox_right_led_1_on();
        ergodox_right_led_2_on();
        ergodox_right_led_3_on();
        break;
      default:
        break;
    }
    return state;

};
