{ pkgs, ... }:

# Playing, recording, and editing audio, video, and images.
{
  environment.systemPackages = with pkgs; [
    audacity
    gimp
    mpg123 # used in emacs and other quick mp3 playing
    peek # screen recorder
    spotify # non-free
    vlc
  ];
}
