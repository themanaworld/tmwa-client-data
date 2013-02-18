#!/usr/bin/env python
#-*- coding:utf-8 -*-

import sys
import os
import subprocess
import re
import tempfile

class MapDiff(object):

    @staticmethod
    def check_programs():
        """
            Checks the require programs are available
        """
        def which(program):
            import os
            def is_exe(fpath):
                return os.path.isfile(fpath) and os.access(fpath, os.X_OK)
            fpath, fname = os.path.split(program)
            if fpath:
                if is_exe(program):
                    return program
            else:
                for path in os.environ["PATH"].split(os.pathsep):
                    exe_file = os.path.join(path, program)
                    if is_exe(exe_file):
                        return exe_file
            return None

        platform_programs = MapDiff.PROGRAMS.get(sys.platform, MapDiff.PROGRAMS.get('default'))
        for program in platform_programs.values():
            if not which(program):
                raise Exception('The required "%s" program is missing from your PATH.' % program)

    MAP_RE = re.compile(r'^\d{3}-\d{1}(\.tmx)?$')
    PROGRAMS = {
        'default': {
            'tmxrasterizer': 'tmxrasterizer',
            'im_convert': 'convert',
            'im_display': 'display',
            'git': 'git',
        },
        'win32': {
            'tmxrasterizer': 'tmxrasterizer.exe',
            'im_convert': 'convert.exe',
            'im_display': 'display.exe',
            'git': 'git.exe',
        },
    }

    def __init__(self):
        self.platform_programs = MapDiff.PROGRAMS.get(sys.platform, MapDiff.PROGRAMS.get('default'))

    def _diffmaps(self, tmx1, tmx2, tmxdiffpath):
        tmxraster1 = self._rastermap(tmx1)
        tmxraster2 = self._rastermap(tmx2)
        tmxf, tmxdiff = tempfile.mkstemp(suffix='.png')
        subprocess.check_call([
            self.platform_programs.get('im_convert'), tmxraster1, tmxraster2,
            '-compose', 'Difference',
            '-auto-level',
            '-composite',
            tmxraster2,
            '-compose', 'Screen',
            '-composite',
            tmxdiffpath
        ])
        os.unlink(tmxdiff)
        os.unlink(tmxraster1)
        os.unlink(tmxraster2)
        sys.stdout.write((u'Map diff written to %s\n' % tmxdiffpath).encode('utf-8'))
        subprocess.check_call([self.platform_programs.get('im_display'), tmxdiffpath])

    def _rastermap(self, tmx):
        tmxf, tmxraster = tempfile.mkstemp(suffix='.png')
        subprocess.check_call([
            self.platform_programs.get('tmxrasterizer'),
            '--scale', '1.0',
            tmx, tmxraster
        ])
        if os.stat(tmxraster).st_size == 0:
            raise Exception('A problem was encountered when rendering a map')
        return tmxraster


class MapGitRevDiff(MapDiff):

    def __init__(self, map_name):
        super(MapGitRevDiff, self).__init__()
        self.map_name = map_name

    def diff(self):
        if not MapDiff.MAP_RE.match(self.map_name):
            sys.stderr.write(u'Invalid map name: %s.\n' % self.map_name)
            return 1
        if not self.map_name.endswith(u'.tmx'):
            self.map_name = self.map_name+u'.tmx'
        self.tmx_path = os.path.join(u'..', u'maps', self.map_name)
        self.map_number = os.path.splitext(os.path.basename(self.map_name))[0]
        p = subprocess.Popen([self.platform_programs.get('git'), '--no-pager', 'log', '-n', '2', '--oneline', '--follow', self.tmx_path], stdout=subprocess.PIPE)
        log = p.communicate()[0].splitlines()
        if not len(log) == 2:
            raise Exception('This map has only one version')
        c1 = log[0].split(' ')[0]
        c2 = log[1].split(' ')[0]

        # We have the 2 revs to compare. Let's extract the related tmx file
        p1 = self._mktmx_from_rev(c1)
        p2 = self._mktmx_from_rev(c2)
        try:
            difftmxpath = '%s_%s-%s.png' % (self.map_number, c1, c2)
            self._diffmaps(p1, p2, difftmxpath)
        finally:
            os.unlink(p1)
            os.unlink(p2)

    def _mktmx_from_rev(self, rev):
        p = subprocess.Popen([self.platform_programs.get('git'), '--no-pager', 'show', '%s:%s' % (rev, self.tmx_path)], stdout=subprocess.PIPE)
        contents = p.communicate()[0]
        revtmx = '%s-%s.tmx' % (self.map_number, rev)
        f = open(revtmx, 'w')
        f.write(contents)
        f.close()
        return revtmx


class MapFileDiff(MapDiff):

    def __init__(self, map1, map2):
        super(MapFileDiff, self).__init__()
        self.map1 = map1
        self.map2 = map2

    def diff(self):
        b1 = os.path.splitext(os.path.basename(self.map1))[0]
        b2 = os.path.splitext(os.path.basename(self.map2))[0]
        difftmxpath = '%s__%s.png' % (b1, b2)
        self._diffmaps(self.map1, self.map2, difftmxpath)


def usage():
    sys.stderr.write(u'''Usage: %s MAP_NAME
       %s CHANGED_TMX REFERENCE_TMX

    Example:
        $ ./map-diff.py 007-1
    will highlight the changes between the current 007-1 map and its previous version

        $ ./map-diff.py changes-made-by-someone-007-1.tmx ../maps-007-1.tmx
    will highlight the changes between the two tmx maps.
    Note that these 2 tmx to compare have to satisfy their dependancies, e.g tilesets.
    Hence they should be in a sibling directory of the client-data/maps folder.
    \n''' % (sys.argv[0], sys.argv[0]))

def main():
    if not len(sys.argv) > 1:
        usage()
        return 127
    if not os.path.basename(os.path.dirname(os.getcwdu())) == u'client-data':
        sys.stderr.write(u'This script must be run from client-data/tools.\n')
        return 1
    try:
        MapDiff.check_programs()
    except Exception as e:
        sys.stderr.write(u'%s\n' % e)
        return 126
    if len(sys.argv) == 2:
        map_name = sys.argv[1]
        mapdiff = MapGitRevDiff(map_name)
        try:
            mapdiff.diff()
        except Exception as e:
            sys.stderr.write(u'\x1b[31m\x1b[1mError while generating the diff for map %s: %s\x1b[0m\n' % (map_name, e))
            return 1
        else:
            return 0
    else:
        map1 = sys.argv[1]
        map2 = sys.argv[2]
        mapdiff = MapFileDiff(map1, map2)
        try:
            mapdiff.diff()
        except Exception as e:
            sys.stderr.write(u'\x1b[31m\x1b[1mError while generating the diff for %s and %s: %s\x1b[0m\n' % (map1, map2, e))
            return 1
        else:
            return 0

if __name__ == '__main__':
    sys.exit(main())
