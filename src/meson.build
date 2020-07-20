sagittarius_sources = [
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
  'bytes-utils.vala',
]

sagittarius_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  meson.get_compiler('c').find_library('uriparser'),
  dependency('gmime-3.0', version: '>= 3'),
  dependency('liburiparser-gobject-0'),
  dependency('libdazzle-1.0'),
  dependency('libpeas-1.0'),
  dependency('libpeas-gtk-1.0'),
]

gnome = import('gnome')

sagittarius_sources += gnome.compile_resources('sagittarius-resources',
  'sagittarius.gresource.xml',
  c_name: 'sagittarius'
)

prefix = get_option('prefix')

vala_args = '--target-glib=2.50'
c_args = [
  '-DGETTEXT_PACKAGE="sagittarius"',
  '-DLOCALEDIR="@0@"'.format(localedir),
  '-DLIBDIR="@0@"'.format(join_paths(prefix, get_option('libdir'))),
  '-DDATADIR="@0@"'.format(join_paths(prefix, get_option('datadir'))),
  '-DDEBUG="@0@"'.format(get_option('debug')),
  '-DBUILDDIR="@0@"'.format(meson.current_build_dir()),
]

lib = both_libraries('sagittarius', sagittarius_sources,
  vala_args: vala_args,
  dependencies: sagittarius_deps,
  c_args: c_args,
  # don't install it: this is more meant for compilation
  # TODO is this needed for out-of-tree plugins? if so, it should be optional
  #      and LGPL'd (if needed)
  install: false,
)

exe = executable('sagittarius', [],
  link_with: lib.get_static_lib(),
  dependencies: sagittarius_deps,
  install: true,
)

subdir('parts')
