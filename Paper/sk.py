from pygments.lexer import RegexLexer
from pygments.token import *

class CustomLexer(RegexLexer):
    name = 'Skeleton'
    aliases = ['skeleton','skel','sk','necro']
    filenames = ['*.v']

    tokens = {
        'root': [
            (r'\btype\b', Keyword.Type),
            (r'\bval\b', Keyword.Type),
            (r'\bbinder\b', Keyword.Type),
            (r'\bbranch\b', Keyword.Reserved),
            (r'\bmatch\b', Keyword.Reserved),
            (r'\bwith\b', Keyword.Reserved),
            (r'\bor\b', Keyword.Reserved),
            (r'\bend\b', Keyword.Reserved),
            (r'\blet\b', Keyword.Declaration),
            (r'\bin\b', Keyword.Declaration),
            (r'\bopen [a-zA-Z_][_A-Za-z0-9\']*\b', Comment.Preproc),
            (r'=', Operator),
            (r'<', Operator),
            (r'>', Operator),
            (r'\|', Operator),
            (r',', Operator),
            (r'\*', Operator),
            (r':', Operator),
            (r';', Operator),
            (r'->', Operator),
            (r'→', Operator),
            (r'λ', Operator),
            (r'\\', Operator),
            (r'%[a-z][_A-Za-z0-9\']*', Name.Decorator),
            (r'[!?&*⊤⊥@$^∀∃+-/~][!?&*⊤⊥@$^∀∃+-/~_A-Za-z0-9\']*', Name.Decorator),
            (r'\(\*', Comment.Multiline, 'comment'),
            (r'\(', Operator),
            (r'\)', Operator),
            (r'[A-Z][_A-Za-z0-9\']*', Name.Class),
            (r'[a-z_][_A-Za-z0-9\']*', Text),
            (r'.', Text),
        ],
        'comment': [
            (r'[^\(*]', Comment.Multiline),
            (r'\(\*', Comment.Multiline, '#push'),
            (r'\*\)', Comment.Multiline, '#pop'),
            (r'[*\(]', Comment.Multiline)
        ]
    }

