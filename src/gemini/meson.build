shared_library('gemini',
  [
    '../config.vapi',
    'crypto.c',
    'crypto.vala',
    'plugin.vala',
    'protocol.vala',
    'renderer.vala',
  ],
  install: true,
  install_dir: join_paths(get_option('datadir'), 'sagittarius'),
  c_args: [
    '-DGCR_API_SUBJECT_TO_CHANGE',
    c_args,
  ],
  dependencies: [
    dep,
    dependency('gcr-3'),
    dependency('gcr-ui-3'),
    dependency('gnutls'),
  ],
)

install_data(configure_file(
  input: 'gemini.plugin.in',
  output: 'gemini.plugin',
  configuration: version_conf,
))
