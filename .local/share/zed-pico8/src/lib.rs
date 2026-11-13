// Starts lua-language-server for .p8 carts. The PICO-8 settings (API, syntax,
// cart sections) come from the .luarc.json the pico8 wrapper writes into
// ~/code/pico8, the same as for .lua files there.
use zed_extension_api::{self as zed, LanguageServerId, Result};

struct Pico8;

impl zed::Extension for Pico8 {
    fn new() -> Self {
        Pico8
    }

    fn language_server_command(
        &mut self,
        _id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        let command = worktree.which("lua-language-server").ok_or_else(|| {
            "lua-language-server isn't installed: sudo pacman -S lua-language-server".to_string()
        })?;
        Ok(zed::Command {
            command,
            args: Vec::new(),
            env: Vec::new(),
        })
    }
}

zed::register_extension!(Pico8);
