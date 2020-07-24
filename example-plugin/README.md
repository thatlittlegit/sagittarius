# Example Plugin
This plugin is not connected to the rest of Meson, and is a barebones plugin
for Sagittarius written in C. It illustrates how to use Meson and C to create a
functional plugin, without just using `dep` in meson.build (since you couldn't
do that).

Comments in example-plugin.c and meson.build will guide you through the various
parts of the plugin. The key takeaways are (even if I don't make them obvious):

* Extend SagittariusPlugin, it makes your life easier
* Have a `peas_register_types` function, your plugin must have it
* You need a plugin manifest to work
* Install to `/usr/share/sagittarius/*` (or `$XDG_DATA_DIR/sagittarius/plugins`)
* You *need* to implement PeasActivatable to exist
  * This is done by SagittariusPlugin

This example code is licensed under
[CC0](https://creativecommons.org/publicdomain/zero/1.0/). See the
[LICENSE file](LICENSE) for more details.
