#!/usr/bin/env python3
from subprocess import run
from os import walk, environ, path as ospath

root = environ.get('MESON_SOURCE_ROOT')
srcdir = ospath.join(root, 'src')
config = ospath.join(root, '.uncrustify.cfg')

for path, dirs, files in walk(root):
    for file in files:
        if file.find(".") == -1:
            continue

        filepath = ospath.join(path, file)
        ext = file.rsplit(".", 1)[1]

        if ext == "vala" or ext == "c":
            run(['uncrustify', '-q', filepath, '-c',
                 config, '--replace', '--no-backup'])

        if ext == "xml" or ext == "ui" or file.endswith(".xml.in"):
            run(['xmllint', '--format', filepath, '-o', filepath])
