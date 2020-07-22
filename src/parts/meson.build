parts = [
  'proto-about',
  'proto-gemini',
  'render-gemini',
  'render-welcome',
]

foreach part: parts
  shared_library(part, [ '../config.vapi', '@0@.vala'.format(part) ],
    install: true,
    c_args: c_args,
    dependencies: dep,
  )

  conf = configure_file(
    input: '@0@.plugin.in'.format(part),
    output: '@0@.plugin'.format(part),
    configuration: version_conf,
  )

  install_data(conf)
endforeach
