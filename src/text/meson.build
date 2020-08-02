shared_library('text',
  [
    'settings.vala',
    'text.vala',
    import('gnome').compile_resources('text-resources',
      'text.gresource.xml',
      c_name: 'text',
    )
  ],
  install: true,
  install_dir: join_paths(get_option('datadir'), 'sagittarius'),
  c_args: c_args,
  dependencies: [
    dep,
    dependency('gtksourceview-4', version: '>= 4.0'),
  ],
)

install_data(configure_file(
  input: 'text.plugin.in',
  output: 'text.plugin',
  configuration: version_conf,
))

install_data('text.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)
