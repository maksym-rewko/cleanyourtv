# Source this before building the launcher or touching a TV:   source env.sh
# Sets the Java and Android SDK paths the build needs (Homebrew install, Apple silicon).
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

# TV addresses. They can change after a reboot: check Settings > Network on the TV, or reserve the
# address on your router. Switch TV by changing TV_HOST, e.g.   export TV_HOST=$TV_HISENSE
export TV_SONY=10.0.0.146
export TV_HISENSE=          # fill in when the Hisense is set up
export TV_HOST="$TV_SONY"
