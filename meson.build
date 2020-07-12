project('sagittarius', ['c', 'vala'],
        version: '0.1.0',
  meson_version: '>= 0.40.0',
)

version_conf = configuration_data()
version_conf.set('VERSION', meson.project_version())

i18n = import('i18n')
localedir = join_paths (get_option ('prefix'), get_option ('localedir'))

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('build-aux/postinstall.py')
run_target('beautify', command: 'build-aux/beautify.py')
