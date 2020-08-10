shared_library('text',
  [
    'text.vala',
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
