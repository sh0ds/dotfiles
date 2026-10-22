# Headphone sound

My headset is a Corsair Virtuoso RGB Wireless XT on its USB receiver. Out of the box it's a bit thin in the deep bass and has a dip in the lower mids. [AutoEQ](https://github.com/jaakkopasanen/AutoEq) has a correction for it from Rtings' measurement that bends it to the Harman curve, the tuning most people hear as full and natural. [Easy Effects](https://github.com/wwmm/easyeffects) runs it, with a limiter behind it so the boosted bass never clips and I don't lose volume.

Easy Effects starts at login without a window (`rice.lua`). It puts its own output in front of the headset and makes it the default, so everything goes through it: SoundCloud, mpd, games.

## Setting it up

Do this once, the settings stay in Easy Effects after that.

1. Install it and log out and back in (or run `easyeffects --service-mode &`):

   ```
   sudo pacman -S easyeffects lsp-plugins-lv2
   ```

2. Open the window with `easyeffects` and go to Output. Make sure the device at the bottom is the Virtuoso XT receiver.
3. Add effect, Equalizer. In its menu pick "Import APO" and choose `~/code/dotfiles/docs/audio/virtuoso-xt-autoeq.txt`. That loads the 10 filters and sets the input gain to -6.3 dB.
4. Change the Equalizer's input gain from -6.3 to -2 dB. The limiter in the next step catches the few peaks that would clip, so you get most of the volume back.
5. Add effect, Limiter, below the Equalizer. Threshold -1 dB, lookahead 5 ms, release 20 ms. Leave the rest.
6. Presets, save the current output as `virtuoso`. If it ever gets lost: `easyeffects -l virtuoso`.
7. Turn the headset itself all the way up once, so all volume control happens on the bar:

   ```
   pactl set-sink-volume alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_1c55537f00030217-00.analog-stereo 100%
   ```

If iCUE ever put an EQ preset on the headset itself (it saves it on the headset), set it back to Pure Direct or flat in Windows, otherwise the bass gets boosted twice.

## Flat sound

For DJ cueing in the VM, or to compare: `easyeffects -b 1` turns all effects off, `easyeffects -b 2` back on.
