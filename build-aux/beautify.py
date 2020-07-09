#!/usr/bin/env python3
from subprocess import run
from os import walk, environ, path as ospath

root = environ.get('MESON_SOURCE_ROOT')
srcdir = ospath.join(root, 'src')
config = ospath.join(root, '.uncrustify.cfg')

for path, dirs, files in walk(root):
    for file in files:
        filepath = ospath.join(path, file)

        if file.endswith(".vala") or file.endswith(".c"):
            run(['uncrustify', '-q', filepath, '-c', config, '--replace', '--no-backup'])
        if file.endswith(".xml") or file.endswith(".ui") or file.endswith(".xml.in"):
            run(['xmllint', '--format', filepath, '-o', filepath])
