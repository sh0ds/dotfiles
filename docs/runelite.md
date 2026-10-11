# OSRS setup (RuneLite)

How I get Old School RuneScape looking like the rest of the desktop. Takes about five minutes, once.

## 1. Install and log in

```
sudo pacman -S jre17-openjdk python-pillow
yay -S bolt-launcher
runelite-skin
```

`runelite-skin` downloads the [RuneLITE](https://github.com/melkypie/resource-packs/tree/pack-RuneLITE) resource pack by Smoke, a flat and minimal take on the game's interface, and recolours it to Mocha: its greys become the same shades as the bar and windows, its gold accent becomes mauve. It lands in `~/.local/share/runelite-mocha`. Run it again if the pack ever gets an update.

Log out and back in once so Hyprland picks up the Java settings. Then press `SUPER+R`, log in to Bolt with your Jagex account, pick your character and start RuneLite.

## 2. Import the profile

1. In RuneLite, click the wrench on the right, then the person icon at the top (Profiles).
2. Import Profile. Java's file picker hides dot-folders, so type the full path `/home/sh0ds/.config/runelite/mocha.properties` into the file name field.
3. Click the new "Imported Profile" so it's the active one (it gets a check mark).
4. Close RuneLite and start it again with `SUPER+R`. The Plugin Hub plugins download on that start.

## 3. Game settings

These are saved to your account, so the profile can't set them. In the game, click the wrench in the side panel, then the monitor tab (Display):

- Layout: **Resizable - Classic layout**
- **Transparent chatbox**: on
- Click-through chatbox: on, so you can click the game behind it. It only shows up in All Settings (button at the bottom of the Display tab): type `click` into its search box.

## 4. The skin

Open the Resource Packs plugin (paintbrush in RuneLite's side panel) and check that "Use resource pack" is First and the path is `/home/sh0ds/.local/share/runelite-mocha` (change `sh0ds` if your user is different). If it asks about Interface Styles, say yes. If the interface doesn't change, switch to Second and back to First.

## 5. Check it worked

- Side panel, tabs and minimap are flat Mocha, the selected tab has a mauve line under it, the minimap is an octagon
- Chat text is white with mauve names
- Hovering an NPC gives it a yellow outline
- The sky past the draw distance is dark Mocha
- When you stop chopping a tree or fishing, an "idle" notification pops up in swaync

## What's in the profile

- GPU rendering with double draw distance, 4x anti-aliasing, a little fog and a Mocha sky
- Quest Helper, Inventory Setups, Shortest Path, Dude Where's My Stuff, Clue Details, Banked Experience, Skills Tab Progress Bars
- Farming and birdhouse reminders, idle notifications and high-value drops, all as normal notifications
- HP and prayer bars next to the side panel, item prices on hover, herb and ore names, no roofs, anti-drag, further zoom-out, smoother animations
- Mocha colours for loot, hover outlines, the walk tile, XP globes, chat, overlays, minimap dots, player names, marked NPCs, objects and tiles, XP drops and agility courses
- Emote Clue Items, which shows which emote clue items you own and where they are
- No RuneLite title bar (Hyprland draws the border) and no character name in the window title

## Help

- **RuneLite opened above or below another window**: it should flip to side by side on its own, `SUPER+T` flips it by hand.

- **Black bars or a tiny game**: the layout isn't on Resizable, see step 3.
- **Plugin list is short**: you're still on the default profile, see step 2.3.
- **Brown interface**: step 4, or run `runelite-skin` again if `~/.local/share/runelite-mocha` is missing.
- **Orbs look broken**: LITE Regen Meter isn't on yet, restart RuneLite once so it downloads.
