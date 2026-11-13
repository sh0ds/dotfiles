// Starts lua-language-server for .p8 carts. The PICO-8 settings (API, syntax,
// cart sections) come from the .luarc.json the pico8 wrapper writes into
// ~/code/pico8, the same as for .lua files there.
use zed_extension_api::{self as zed, serde_json, settings::LspSettings, LanguageServerId, Result};

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

    // Settings from "lsp": { "pico8-lua": { ... } } in Zed's settings, like
    // the Lua extension. ~/code/pico8/.zed/settings.json (written by the
    // pico8 wrapper) sets trustByClient there, so the server runs
    // pico8-plugin.lua without asking (it would ask in a prompt Zed doesn't show).
    fn language_server_initialization_options(
        &mut self,
        id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>> {
        LspSettings::for_worktree(id.as_ref(), worktree)
            .map(|settings| settings.initialization_options.clone())
    }

    fn language_server_workspace_configuration(
        &mut self,
        id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>> {
        LspSettings::for_worktree(id.as_ref(), worktree).map(|settings| settings.settings.clone())
    }
}

zed::register_extension!(Pico8);
