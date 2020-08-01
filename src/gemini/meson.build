shared_library('gemini',
  [
    '../config.vapi',
    'crypto.vala',
    'plugin.vala',
    'protocol.vala',
    'renderer.vala',
  ],
  install: true,
  install_dir: join_paths(get_option('datadir'), 'sagittarius'),
  c_args: c_args,
  dependencies: [
    dep,
    dependency('gnutls'),
  ],
)

install_data(configure_file(
  input: 'gemini.plugin.in',
  output: 'gemini.plugin',
  configuration: version_conf,
))
