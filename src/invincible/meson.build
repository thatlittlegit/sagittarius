shared_library('invincible',
  [
    '../config.vapi',
    'invincible.vala',
  ],
  install: true,
  install_dir: join_paths(get_option('datadir'), 'sagittarius'),
  c_args: c_args,
  dependencies: [
    dep,
    dependency('evince-document-3.0'),
    dependency('evince-view-3.0'),
  ],
  vala_args: ['--vapidir', join_paths(meson.source_root(), 'src', 'invincible')],
)

install_data(configure_file(
  input: 'invincible.plugin.in',
  output: 'invincible.plugin',
  configuration: version_conf,
))
