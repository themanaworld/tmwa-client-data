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

class MinimapRenderer(object):

    MAP_RE = re.compile(r'^\d{3}-\d{1}(\.tmx)?$')
    PROGRAMS = {
        'default': {
            'tmxrasterizer': 'tmxrasterizer',
            'im_convert': 'convert',
        },
        'win32': {
            'tmxrasterizer': 'tmxrasterizer.exe',
            'im_convert': 'convert.exe',
        },
    }

    def __init__(self, map_name, tilesize, useAntiAliasing):
        self.map_name = map_name
        self.tilesize = tilesize
        self.useAntiAliasing = useAntiAliasing

    def render(self):
        """
            Processes a map
        """
        if not MinimapRenderer.MAP_RE.match(self.map_name):
            sys.stderr.write(u'Invalid map name: %s. Skipping.\n' % self.map_name)
            return 1
        if not self.map_name.endswith(u'.tmx'):
            self.map_name = self.map_name+u'.tmx'

        map_number = os.path.splitext(os.path.basename(self.map_name))[0]
        tmx_file = os.path.join(CLIENT_DATA_ROOT, u'maps', self.map_name)
        minimap_file = os.path.join(CLIENT_DATA_ROOT, u'graphics', u'minimaps', map_number+u'.png')

        prefix = os.path.commonprefix((tmx_file, minimap_file))
        sys.stdout.write(u'%s -> %s\n' % (os.path.relpath(tmx_file, prefix), os.path.relpath(minimap_file, prefix)))

        try:
            self.do_render(tmx_file, minimap_file)
        except Exception as e:
            sys.stderr.write(u'\x1b[31m\x1b[1mError while rendering %s: %s\x1b[0m\n' % (self.map_name, e))
            return 1
        else:
            return 0

    def do_render(self, tmx_file, bitmap_file):
        """
            The map rendering implementation
        """
        platform_programs = MinimapRenderer.PROGRAMS.get(sys.platform, MinimapRenderer.PROGRAMS.get('default'))
        # tmx rasterize
        mrf, map_raster = tempfile.mkstemp(suffix='.png')
        tmxrasterizer_cmd = [
            platform_programs.get('tmxrasterizer'),
            '--tilesize', str(self.tilesize),
        ]
        if self.useAntiAliasing:
            tmxrasterizer_cmd.append('--anti-aliasing')
        tmxrasterizer_cmd += [tmx_file, map_raster]
        subprocess.check_call(tmxrasterizer_cmd)
        if os.stat(map_raster).st_size == 0:
            raise Exception('A problem was encountered when rendering a map')
        # add cell-shading to the minimap to improve readability
        ebf, edges_bitmap = tempfile.mkstemp(suffix='.png')
        subprocess.check_call([
            platform_programs.get('im_convert'), map_raster,
            '-set', 'option:convolve:scale', '-1!',
            '-morphology', 'Convolve', 'Laplacian:0',
            '-colorspace', 'gray',
            '-auto-level',
            '-threshold', '2.8%',
            '-negate',
            '-transparent', 'white',
            edges_bitmap
        ])
        subprocess.check_call([
            platform_programs.get('im_convert'), map_raster, edges_bitmap,
            '-compose', 'Dissolve',
            '-define', 'compose:args=35',
            '-composite',
            bitmap_file
        ])
        os.unlink(map_raster)
        os.unlink(edges_bitmap)

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

        platform_programs = MinimapRenderer.PROGRAMS.get(sys.platform, MinimapRenderer.PROGRAMS.get('default'))
        for program in platform_programs.values():
            if not which(program):
                raise Exception('The required "%s" program is missing from your PATH.' % program)

def usage():
    sys.stderr.write(u'''Usage: %s MAP_NAME...

    Example:
        $ ./minimap-render.py 007-1
    will render the map at maps/007-1.tmx in the graphics/minimaps directory.
        $ ./minimap-render.py all
    will render all existing maps found in the maps directory.
        $ ./minimap-render.py update
    will update all existing minimaps found in the graphics/minimaps directory.

    For convenience,
        $ ./minimap-render.py 007-1.tmx
    is also accepted.
    \n''' % sys.argv[0])

def main():
    if not len(sys.argv) > 1:
        usage()
        return 127
    try:
        MinimapRenderer.check_programs()
    except Exception as e:
        sys.stderr.write(u'%s\n' % e)
        return 126

    status = 0
    if sys.argv[1].lower() == 'all':
        map_names = sorted([os.path.splitext(p)[0] for p in os.listdir(os.path.join(CLIENT_DATA_ROOT, u'maps'))])
    elif sys.argv[1].lower() == 'update':
        map_names = sorted([os.path.splitext(p)[0] for p in os.listdir(os.path.join(CLIENT_DATA_ROOT, u'graphics', u'minimaps'))])
    else:
        map_names = sys.argv[1:]

    for map_name in map_names:
        # Render tiles at 1 pixel size
        map_renderer = MinimapRenderer(map_name, 1, True)
        status += map_renderer.render()
    return status

if __name__ == '__main__':
    sys.exit(main())
