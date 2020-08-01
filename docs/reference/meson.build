# TODO use disabler upon 0.49
valadoc = find_program('valadoc', required: false)

if not valadoc.found()
  subdir_done()
endif

doc_target = custom_target('documentation',
  command: [
    valadoc,
    '--pkg=glib-2.0',
    '--pkg=gmime-3.0',
    '--pkg=gobject-2.0',
    '--pkg=gtk+-3.0',
    '--pkg=libdazzle-1.0',
    '--pkg=libpeas-1.0',
    '--pkg=libpeas-gtk-1.0',
    '--pkg=liburiparser-gobject-0',
    '-b', '../../src',
    src,
    '--package-name=' + meson.project_name(),
    '--package-version=' + meson.project_version(),
    '--use-svg-images',
    '-o', meson.current_build_dir(),
    '--force',
    '--verbose',
  ],
  build_by_default: true,
  output: '.',
  depends: lib,
)
