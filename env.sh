# Source this before building the launcher or touching a TV:   source env.sh
# Sets the Java and Android SDK paths the build needs (Homebrew install, Apple silicon).
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

# TV addresses live in env.local.sh (gitignored, stays on this Mac). Copy env.local.sh.example to start.
# Switch TV by changing TV_HOST, e.g.   export TV_HOST=$TV_HISENSE
_here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -f "$_here/env.local.sh" ]; then . "$_here/env.local.sh"; else echo "env.sh: no env.local.sh, copy env.local.sh.example and fill in your TV IPs" >&2; fi
unset _here
