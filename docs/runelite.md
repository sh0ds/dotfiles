# OSRS setup (RuneLite)

How I get Old School RuneScape looking like the rest of the desktop. Takes about ten minutes, once.

## 1. Install

```
sudo pacman -S --needed jre17-openjdk python-pillow
yay -S bolt-launcher
```

Log out and back in once so Hyprland picks up the Java settings.

## 2. First start

Press `SUPER+R`, log in to Bolt with your Jagex account, pick your character and start RuneLite. Once it's open, close it again. This first start only creates RuneLite's folders.

## 3. Build the skin

```
runelite-skin
```

It downloads the [RuneLITE](https://github.com/melkypie/resource-packs/tree/pack-RuneLITE) resource pack by Smoke, a flat and minimal take on the game's interface, and recolours it to Mocha: its greys become the same shades as the bar and windows, its gold accent becomes mauve. It lands in `~/.local/share/runelite-mocha`. It also puts your current wallpaper on the login screen. Run it again after changing wallpaper or when the pack gets an update.

## 4. Import the profile

1. Start RuneLite with `SUPER+R`. Click the wrench on the right, then the person icon at the top (Profiles).
2. Import Profile. Java's file picker hides dot-folders, so type the full path `/home/sh0ds/.config/runelite/mocha.properties` into the file name field.
3. Click the new "Imported Profile" so it's the active one (it gets a check mark).
4. Close RuneLite and start it again with `SUPER+R`. The Plugin Hub plugins download on that start.

## 5. Game settings

These are saved to your account, so the profile can't set them. In the game, click the wrench in the side panel, then the monitor tab (Display):

- Layout: **Resizable - Classic layout**
- **Transparent chatbox**: on
- Click "All Settings" at the bottom, type `click` into the search box and turn on **Click through transparent chatbox**, so you can click the game behind the chat.

## 6. Check the skin

Open the Resource Packs plugin (paintbrush in RuneLite's side panel). "Use resource pack" should be First and the path `/home/sh0ds/.local/share/runelite-mocha` (change `sh0ds` if your user is different). If it asks about Interface Styles, say yes. If the interface doesn't change, switch to Second and back to First.

## 7. Check it all worked

- The login screen is your wallpaper, without the fire
- RuneLite opens next to your other window, not above or below it, and doesn't dim when you click away
- Side panel, tabs and minimap are flat Mocha, the selected tab has a mauve line under it, the minimap is an octagon
- Chat text is white with mauve names, overlays have the same see-through background as the bar
- Hovering an NPC gives it a yellow outline, the minimap dots are Mocha colours
- The sky past the draw distance is dark Mocha
- When you stop chopping a tree or fishing, an "idle" notification pops up in swaync

## What's in the profile

- GPU rendering with double draw distance, 4x anti-aliasing, a little fog and a Mocha sky
- Quest Helper, Inventory Setups, Shortest Path, Dude Where's My Stuff, Banked Experience, Skills Tab Progress Bars, Emote Clue Items
- Farming and birdhouse reminders, idle notifications and high-value drops, all as normal notifications
- HP and prayer bars next to the side panel, item prices on hover, herb and ore names, no roofs, anti-drag, further zoom-out, smoother animations
- Mocha colours for loot, hover outlines, the walk tile, XP globes, chat, overlays, minimap dots, player names, marked NPCs, objects and tiles, XP drops and agility courses (shift+right-click an object or tile to mark it)
- No RuneLite title bar (Hyprland draws the border) and no character name in the window title

## Help

- **RuneLite opened above or below another window**: `SUPER+T` flips it to side by side.
- **Black bars or a tiny game**: the layout isn't on Resizable, see step 5.
- **Plugin list is short**: you're still on the default profile, see step 4.3.
- **Brown interface**: step 6, or run `runelite-skin` again if `~/.local/share/runelite-mocha` is missing.
- **Normal login screen**: run `runelite-skin` again now that RuneLite has started once.
- **Orbs look broken**: LITE Regen Meter isn't on yet, restart RuneLite once so it downloads.
