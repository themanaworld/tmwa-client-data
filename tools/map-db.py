#!/usr/bin/env python
#-*- coding:utf-8 -*-

import sys
import os
import subprocess
import tempfile
import re

CLIENT_DATA_ROOT = os.path.realpath(
    os.path.join(
        os.path.dirname(__file__),
        u'..',
    )
)

MAP_RE = re.compile(r'^(\d{3})-(\d{1})$')

def list_missing_minimaps(maps, minimaps):
    def minimap_wanted(m):
        match = MAP_RE.match(m)
        if match:
            d = match.group(2)
            # We ignore indoor maps
            if not d == '2':
                return True
        return False

    missing_minimaps = set([m for m in maps if minimap_wanted(m)]) - set(minimaps)
    retcode = len(missing_minimaps)
    print '\n'.join(sorted(missing_minimaps))
    return retcode

def usage():
    sys.stderr.write(u'''Usage: %(prgm_name)s CMD

    Where CMD is one of:
        list-missing-minimaps, lm:      Lists all maps which do not
                                        have a minimap.

    \n''' % {'prgm_name': sys.argv[0]})

def main():
    if not len(sys.argv) > 1:
        usage()
        return 127
    action = sys.argv[1].lower()
    maps = [os.path.splitext(p)[0] for p in os.listdir(os.path.join(CLIENT_DATA_ROOT, u'maps'))]
    minimaps = [os.path.splitext(p)[0] for p in os.listdir(os.path.join(CLIENT_DATA_ROOT, u'graphics', u'minimaps'))]
    status = 0
    if action in ('list-missing-minimaps', 'lm'):
        status = list_missing_minimaps(maps, minimaps)
    else:
        usage()
        return 127
    return status

if __name__ == '__main__':
    sys.exit(main())
