#!/usr/bin/env python3
#
# Copyright (c) 2010, Philipp Stephani <st_philipp@yahoo.de>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import re
import optparse
import os
import gzip

# HACK
if not hasattr(gzip.GzipFile, "__enter__"):
    gzip.GzipFile.__enter__ = lambda self: self

if not hasattr(gzip.GzipFile, "__exit__"):
    gzip.GzipFile.__exit__ = lambda self, exc_type, exc_val, exc_tb: False


pattern = re.compile(br"^(Input:\d+:)([^/].*)$", re.M)


def fix_synctex_info(fname, input_dir):
    def replace(match):
        return (match.group(1)
                + (os.path.normpath
                   (os.path.join(input_dir.encode(), match.group(2)))))
    open_file = gzip.open if fname.endswith(".gz") else open
    with open_file(fname, "rb") as stream:
        text = stream.read()
    text = pattern.sub(replace, text)
    with open_file(fname, "wb") as stream:
        stream.write(text)


def main():
    parser = optparse.OptionParser("Usage: %prog [options] files")
    parser.add_option("-d", "--input-directory", metavar="DIR",
                      help=("use DIR as input directory "
                            "[default: current directory]"))
    parser.set_defaults(input_directory=os.getcwd())
    options, args = parser.parse_args()
    for fname in args:
        fix_synctex_info(fname, options.input_directory)


if __name__ == "__main__":
    main()
