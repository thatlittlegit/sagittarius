shared_library('gemini',
  [
    '../config.vapi',
    'plugin.vala',
    'protocol.vala',
    'renderer.vala',
  ],
  install: true,
  install_dir: join_paths(get_option('datadir'), 'sagittarius'),
  c_args: c_args,
  dependencies: dep,
)

install_data(configure_file(
  input: 'gemini.plugin.in',
  output: 'gemini.plugin',
  configuration: version_conf,
))
