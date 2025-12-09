# pnpm
export PNPM_HOME="/Users/edd/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/Users/edd/yes/_bun" ] && source "/Users/edd/yes/_bun"

# bun
export BUN_INSTALL="yes"
export PATH="$BUN_INSTALL/bin:$PATH"
