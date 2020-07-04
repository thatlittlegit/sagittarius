sagittarius_sources = [
  'gemini-protocol.vala',
  'main.vala',
  'window.vala',
  'config.vapi',
  'gemini-markup.vala',
  'error.vala',
  'application.vala',
  'tab.vala',
  'history.vala',
  'about-protocol.vala',
  'uri-loader.vala',
]

sagittarius_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  meson.get_compiler('c').find_library('uriparser'),
  dependency('gmime-3.0', version: '>= 3'),
  dependency('liburiparser-gobject-0'),
  dependency('libdazzle-1.0'),
]

gnome = import('gnome')

sagittarius_sources += gnome.compile_resources('sagittarius-resources',
  'sagittarius.gresource.xml',
  c_name: 'sagittarius'
)

executable('sagittarius', sagittarius_sources,
  vala_args: '--target-glib=2.50',  dependencies: sagittarius_deps,
  c_args: [
    '-DGETTEXT_PACKAGE="sagittarius"',
    '-DLOCALEDIR="@0@"'.format(localedir),
  ],
  install: true,
)
