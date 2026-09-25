{ pkgs, ... }:

# Study tools: spaced-repetition flashcards and chess study.
{
  environment.systemPackages = with pkgs; [
    anki
    pgn-extract # chess utils
    # scid-vs-pc # chess
  ];
}
