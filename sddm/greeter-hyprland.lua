-- Minimal Hyprland config for the SDDM greeter (runs as user "sddm").
-- Exists mainly so Hyprland doesn't autogenerate a config and show its banner.
hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		background_color = "rgb(1d2021)",
	},
	animations = { enabled = false },
})
