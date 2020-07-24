# meson.build
#
# By thatlittlegit for the Sagittarius project.
# This file is licensed under the CC0 license, with NO WARRANTY OR LIABILITY.
# You should've recieved a copy of the CC0 license with this software; if you
# didn't, visit <https://creativecommons.org/publicdomain/zero/1.0>.
#
# This file is completely separate from the rest of the Sagittarius toolchain,
# to demonstrate (and test!) plugins that can't just say 'dependencies: dep'.

# Do note that you might need to replace x / y / z with join_paths(x, y, z) if
# you need meson <= 0.49.0 or so.

# This is a standard-enough C project definition, nothing to see here.
project('example-plugin', 'c',
  version: '0.1.0',
  meson_version: '>= 0.50.0',
)

# Here, we build a shared library. YOU DON'T WANT A STATIC LIBRARY --- these
# can't be loaded at runtime. Thanks to the pkg-config definition, we can just
# tell meson that Peas and Sagittarius are dependencies.
shared_library('example-plugin', 'example-plugin.c',
  dependencies: [
    dependency('sagittarius'),
    dependency('libpeas-1.0'),
  ],
  install: true,
  install_dir: get_option('prefix') / get_option('datadir') / 'sagittarius',
)

# Now, we make a configuration_data object for filling in the version of
# example-plugin.plugin.in. We then instruct meson to install the replaced
# one as `example-plugin.plugin'.
# NOTE: if you need to support Meson <= 0.50.0, use install_data around
#       configure_file.
configuration = configuration_data()
configuration.set('VERSION', meson.project_version())
configure_file(
  input: 'example-plugin.plugin.in',
  output: 'example-plugin.plugin',
  configuration: configuration,
  install: true,
  install_dir: get_option('datadir') / 'sagittarius',
)

# ...and we're done! We now are building a Sagittarius plugin. meson's great.
