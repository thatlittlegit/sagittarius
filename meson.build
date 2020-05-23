project('sagittarius', ['c', 'vala'],
        version: '0.1.0',
  meson_version: '>= 0.40.0',
)

i18n = import('i18n')
localedir = join_paths (get_option ('prefix'), get_option ('localedir'))

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('build-aux/meson/postinstall.py')
run_target('beautify', command: 'build-aux/beautify.py')
