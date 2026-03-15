# Claude - my setup

Portable Claude CLI configuration. Clone this repo and run `install.sh` to symlink config
files into `~/.claude/`.

## New machine setup

```bash
git clone <this-repo> ~/dev/claude
cd ~/dev/claude
chmod +x install.sh
./install.sh
```

Then install plugins manually inside Claude:
- `explanatory-output-style@claude-plugins-official`
- `claude-md-management@claude-plugins-official`
- `jdtls-lsp@claude-plugins-official`
- `rust-analyzer-lsp@claude-plugins-official`
