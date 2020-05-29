sagittarius_sources = [
  'gemini.vala',
  'main.vala',
  'window.vala',
  'config.vapi',
  'gemini-markup.vala',
  'uri.c',
  'uri.c.vala',
  'error.vala',
  'application.vala',
  'tab.vala',
  'history.vala',
]

sagittarius_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('granite', version: '>= 5.2'),
  meson.get_compiler('c').find_library('uriparser'),
  dependency('gmime-3.0', version: '>= 3'),
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
