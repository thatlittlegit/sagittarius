shared_library('about',
  [
    'protocol.vala',
    import('gnome').compile_resources('about-resources',
      'about.gresource.xml',
      c_name: 'about',
    )
  ],
  install: true,
  install_dir: join_paths(get_option('datadir'), 'sagittarius'),
  c_args: c_args,
  dependencies: dep,
)

install_data(configure_file(
  input: 'about.plugin.in',
  output: 'about.plugin',
  configuration: version_conf,
))
