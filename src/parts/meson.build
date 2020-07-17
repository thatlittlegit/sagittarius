parts = [
  'proto-about',
  'proto-gemini',
]

foreach part: parts
  shared_library(part, [ '../config.vapi', '@0@.vala'.format(part) ],
    install: true,
    c_args: c_args,
    dependencies: declare_dependency(
      link_with: lib.get_shared_lib(),
      dependencies: sagittarius_deps,
      include_directories: '..'),
  )

  conf = configure_file(
    input: '@0@.plugin.in'.format(part),
    output: '@0@.plugin'.format(part),
    configuration: version_conf,
  )

  install_data(conf)
endforeach
