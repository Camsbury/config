#include QMK_KEYBOARD_H
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
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  [0] = LAYOUT_ergodox(KC_NO, KC_PGDN, KC_PGUP, KC_MEDIA_PREV_TRACK, KC_MEDIA_NEXT_TRACK, KC_MEDIA_PLAY_PAUSE, LCTL(KC_Q), KC_TAB, KC_Q, KC_W, KC_F, KC_P, KC_G, LGUI(KC_X), LT(1, KC_LBRACKET), KC_A, KC_R, KC_S, KC_T, KC_D, KC_LSPO, KC_Z, KC_X, KC_C, KC_V, KC_B, KC_CAPSLOCK, KC_HYPR, KC_LALT, LSFT(KC_LALT), KC_MEH, KC_LGUI, KC_NO, KC_NO, KC_NO, KC_SPACE, LT(2, KC_ESC), KC_LCTL, KC_NO, KC_AUDIO_MUTE, KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN, LGUI(KC_KP_PLUS), LGUI(KC_MINUS), KC_NO, KC_APP, KC_J, KC_L, KC_U, KC_Y, KC_COLN, KC_DELETE, KC_H, KC_N, KC_E, KC_I, KC_O, LT(1, KC_RBRACKET), KC_NO, KC_K, KC_M, KC_COMMA, KC_DOT, KC_SLASH, KC_RSPC, KC_LGUI, KC_MEH, LSFT(KC_LALT), KC_LALT, KC_HYPR, KC_NO, KC_NO, KC_NO, KC_LCTL, LT(2, KC_ENTER), KC_BSPACE),
  [1] = LAYOUT_ergodox(KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_DLR, KC_CIRC, KC_HASH, KC_UNDS, KC_NO, KC_NO, KC_TRNS, KC_PLUS, KC_ASTERISK, KC_EQUAL, KC_MINUS, KC_QUES, KC_LCBR, KC_LEFT, KC_DOWN, KC_UP, KC_RIGHT, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, RESET, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_AT, KC_PERC, KC_PIPE, KC_SCOLON, KC_NO, KC_EXLM, KC_QUOTE, KC_DQUO, KC_GRAVE, KC_TILD, KC_TRNS, KC_NO, KC_NO, KC_AMPR, KC_LABK, KC_RABK, KC_BSLASH, KC_RCBR, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_F13, KC_NO, KC_NO, KC_NO, TO(3), KC_NO),
  [2] = LAYOUT_ergodox(LCTL(LSFT(KC_J)), KC_F1, KC_F2, KC_F3, KC_F4, KC_F5, LGUI(LSFT(KC_C)), KC_NO, LALT(KC_1), LALT(KC_2), LALT(KC_3), LALT(KC_4), LALT(KC_5), KC_NO, KC_NO, KC_1, KC_2, KC_3, KC_4, KC_5, KC_LCTL, LSFT(LALT(KC_1)), LSFT(LALT(KC_2)), LSFT(LALT(KC_3)), LSFT(LALT(KC_4)), LSFT(LALT(KC_5)), KC_NO, KC_NO, KC_LALT, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_TRNS, KC_NO, KC_NO, KC_F6, KC_F7, KC_F8, KC_F9, KC_F10, KC_F11, KC_NO, LALT(KC_6), LALT(KC_7), LALT(KC_8), LALT(KC_9), LALT(KC_0), KC_F12, KC_6, KC_7, KC_8, KC_9, KC_0, KC_NO, KC_NO, LSFT(LALT(KC_6)), LSFT(LALT(KC_7)), LSFT(LALT(KC_8)), LSFT(LALT(KC_9)), LSFT(LALT(KC_0)), KC_LCTL, KC_NO, KC_NO, KC_NO, KC_LALT, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_TRNS, KC_NO),
  [3] = LAYOUT_ergodox(KC_LCTL, KC_1, KC_2, KC_3, KC_4, KC_5, KC_6, KC_TAB, KC_Q, KC_W, KC_F, KC_P, KC_G, KC_7, KC_BSPACE, KC_A, KC_R, KC_S, KC_T, KC_D, KC_LSPO, KC_Z, KC_X, KC_C, KC_V, KC_B, KC_8, KC_F1, KC_F2, KC_F3, KC_LALT, KC_LCTL, KC_9, KC_0, KC_BSPACE, KC_SPC, LT(4, KC_ESC), KC_LSFT, TO(5), KC_AUDIO_MUTE, KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN, LGUI(KC_PLUS), LGUI(KC_MINUS), TO(0), KC_APP, KC_J, KC_L, KC_U, KC_Y, KC_COLN, KC_DELETE, KC_H, KC_N, KC_E, KC_I, KC_O, LT(1, KC_RBRACKET), KC_NO, KC_K, KC_M, KC_COMMA, KC_DOT, KC_SLASH, KC_F15, KC_LGUI, KC_LALT, KC_MEH, KC_HYPR, KC_F16, KC_F14, KC_NO, KC_NO, KC_LCTL, LT(2, KC_ENTER), KC_BSPACE),
  [4] = LAYOUT_ergodox(KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_P1, KC_P4, KC_P7, KC_NO, KC_NO, KC_DEL, KC_NO, KC_F3, KC_F2, KC_F1, KC_NO, KC_INS, KC_NO, KC_P2, KC_P5, KC_P8, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO),
  [5] = LAYOUT_ergodox(KC_ESC, KC_1, KC_2, KC_3, KC_4, KC_5, KC_6, KC_TAB, KC_Q, KC_W, KC_F, KC_P, KC_G, KC_HOME, KC_LBRACKET, KC_A, KC_R, KC_S, KC_T, KC_D, KC_RBRACKET, KC_Z, KC_X, KC_C, KC_V, KC_B, KC_QUOTE, LCA(KC_NO), KC_MEH, KC_8, KC_9, S(KC_LCTL), KC_MEH, LCA(KC_NO), LSA(KC_NO), KC_LSFT, KC_LCTL, KC_LALT, KC_NO, KC_AUDIO_MUTE, KC_AUDIO_VOL_UP, KC_AUDIO_VOL_DOWN, LGUI(KC_PLUS), LGUI(KC_MINUS), TO(0), LGUI(KC_SPC), KC_J, KC_L, KC_U, KC_Y, KC_COLN, KC_DELETE, KC_H, KC_N, KC_E, KC_I, KC_O, KC_RBRACKET, KC_NO, KC_K, KC_M, KC_COMMA, KC_DOT, KC_SLASH, KC_RSPC, KC_LGUI, KC_LALT, KC_MEH, KC_HYPR, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_ENTER, KC_BSPACE)
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

// Where you put your custom commands
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
    /* case EPRM: */
    /*   if (record->event.pressed) { */
    /*     eeconfig_init(); */
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
