"   Copyright: Copyright (C) 2013 Yann Kaiser
"   License: The MIT License
"
" Use something like
"   inoremap  =InsertSuper()
" in your python ftplugin folder/file
python << EOF
import re

import vim


def _count_indent(line):
    for c in line:
        if c == ' ':
            yield 1
        elif c == '\t':
            yield 8
        else:
            break


def count_indent(line):
    return sum(_count_indent(line))


def find_kw(b, row, kw):
    kw += ' '
    indent = count_indent(b[row])
    for row_ in range(row - 1, 0, -1):
        line = b[row_]
        if count_indent(line) < indent and line.lstrip().startswith(kw):
            return row_
    else:
        raise ValueError(kw)


cls_def = re.compile(r'class (?P<name>\w+)\s*[:(]')

def cls_get_name(b, row):
    return cls_def.search(b[row]).group('name')


fn_def = re.compile(r'def (?P<name>\w+)\s*(?P<paren>\()')

def fn_get_name_args(b, row):
    m = fn_def.search(b[row])
    return m.group('name'), fn_get_arg_names(b, row, m.end('paren'))


def fn_get_arg_names(b, row, col):
    parens = 0
    arg = ''
    stars = ''
    for line in b[row:]:
        for c in line[col:]:
            if c.isalnum() or c == '_':
                if not parens:
                    arg += c
            elif c == '*':
                if not parens:
                    stars += c
            else:
                if arg:
                    yield stars + arg
                    arg = ''
                    stars = ''
                if c in '{[(':
                    parens += 1
                elif c in '}])':
                    parens -= 1
            if parens < 0:
                return
        col = 0
    yield col


def build_super(buf, row):
    def_row = find_kw(buf, row, 'def')
    cls_row = find_kw(buf, row, 'class')
    fn_name, args = fn_get_name_args(buf, def_row)
    cls_name = cls_get_name(buf, cls_row)
    args = list(args)
    return 'super({0}, {1}).{2}({3})'.format(
        cls_name, args[0], fn_name, ', '.join(args[1:]))


def _InsertSuper():
    return build_super(vim.current.buffer, vim.current.window.cursor[0] - 1)
EOF

function! InsertSuper()
return pyeval('_InsertSuper()')
endfunction
