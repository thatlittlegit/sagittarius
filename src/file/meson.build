shared_library('file',
  [
    'protocol.vala',
  ],
  install: true,
  install_dir: join_paths(get_option('datadir'), 'sagittarius'),
  c_args: c_args,
  dependencies: dep,
)

install_data(configure_file(
  input: 'file.plugin.in',
  output: 'file.plugin',
  configuration: version_conf,
))
