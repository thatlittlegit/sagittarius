# Sagittarius
Sagittarius is a browser for the Gemini protocol. It can currently display
response bodies as plaintext, and do basic redirects. It also crashes
frequently.

It is licensed under the GPL 3.0 license.

## Building
Build with meson. Note that when built, `libsagittarius.so` needs to be in your
shared-library search path. Consider configuring meson with `/usr` for the
prefix.
