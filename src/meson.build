src = files(
  'main.vala',
  'window.vala',
  'config.vapi',
  'error.vala',
  'application.vala',
  'tab.vala',
  'history.vala',
  'uri-loader.vala',
  'plugins.vala',
  'renderer.vala',
  'utils.vala',
)

_sagittarius_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('gmime-3.0', version: '>= 3'),
  dependency('liburiparser-gobject-0'),
  dependency('libdazzle-1.0'),
  dependency('libpeas-1.0'),
  dependency('libpeas-gtk-1.0'),
]
sagittarius_deps = [
  _sagittarius_deps,
  meson.get_compiler('c').find_library('uriparser'),
]

gnome = import('gnome')

sagittarius_sources = src + gnome.compile_resources('sagittarius-resources',
  'sagittarius.gresource.xml',
  c_name: 'sagittarius'
)

prefix = get_option('prefix')

vala_args = '--target-glib=2.50'
c_args = [
  '-DGETTEXT_PACKAGE="sagittarius"',
  '-DLOCALEDIR="@0@"'.format(localedir),
  '-DPLUGINDIR="@0@"'.format(join_paths(prefix, get_option('datadir'), 'sagittarius')),
  '-DDEBUG="@0@"'.format(get_option('debug')),
  '-DBUILT_PLUGINDIR="@0@"'.format(join_paths(meson.current_build_dir())),
]

lib = shared_library('sagittarius', sagittarius_sources,
  vala_args: vala_args,
  vala_header: 'sagittarius.h',
  dependencies: sagittarius_deps,
  c_args: c_args,
  install: true,
  install_dir: [true, get_option('includedir'), true ],
)

dep = declare_dependency(
  dependencies: sagittarius_deps,
  link_with: lib,
  include_directories: '.',
)

import('pkgconfig').generate(lib,
  name: 'sagittarius',
  description: 'A browser for the Gemini protocol.',
  # FIXME only depend on libpeas/gobject
  requires: _sagittarius_deps,
)

exe = executable('sagittarius', [],
  link_with: lib,
  dependencies: sagittarius_deps,
  install: true,
)

subdir('about')
subdir('gemini')
subdir('invincible')
subdir('text')
