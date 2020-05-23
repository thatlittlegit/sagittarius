#!/usr/bin/env python3
from subprocess import call
from os import walk, environ, path as ospath

root = environ.get('MESON_SOURCE_ROOT')
srcdir = ospath.join(root, 'src')
config = ospath.join(root, '.uncrustify.cfg')

for path, dirs, files in walk(root):
    for file in files:
        if file.endswith(".vala"):
            call(['uncrustify', '-q', ospath.join(path, file), '-c', config, '--replace', '--no-backup'])
        if file.endswith(".xml") or file.endswith(".ui") or file.endswith(".xml.in"):
            filepath = ospath.join(path, file)
            call(['xmllint', '--format', filepath, '-o', filepath])
