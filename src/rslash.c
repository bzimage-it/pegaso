#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void print_help(const char *progname) {
    fprintf(stderr,
        "Usage: %s [OPTIONS] [STRINGS...]\n"
        "Transforms '/' to '\\' and vice versa (involutive).\n\n"
        "Options:\n"
        "  -i0         Use '\\0' as input separator (default '\\n')\n"
        "  -o0         Use '\\0' as output separator (default '\\n')\n"
        "  -h, --help  Show this help message and exit\n\n"
        "If no strings are provided, reads from stdin.\n",
        progname
    );
}

int main(int argc, char *argv[]) {
    int use_null_input = 0;
    int use_null_output = 0;
    int arg_index = 1;

    // Parse options
    while (arg_index < argc && argv[arg_index][0] == '-') {
        if (strcmp(argv[arg_index], "-i0") == 0) {
            use_null_input = 1;
        } else if (strcmp(argv[arg_index], "-o0") == 0) {
            use_null_output = 1;
        } else if (strcmp(argv[arg_index], "-h") == 0 || strcmp(argv[arg_index], "--help") == 0) {
            print_help(argv[0]);
            return 0;
        } else {
            fprintf(stderr, "Unknown option: %s\n", argv[arg_index]);
            return 1;
        }
        arg_index++;
    }

    char sep_in = use_null_input ? '\0' : '\n';
    char sep_out = use_null_output ? '\0' : '\n';

    if (arg_index < argc) {
        // Read from remaining arguments
        for (int i = arg_index; i < argc; i++) {
            const char *s = argv[i];
            while (*s) {
                if (*s == '/') putchar('\\');
                else if (*s == '\\') putchar('/');
                else putchar(*s);
                s++;
            }
            putchar(sep_out);
        }
    } else {
        // Read from stdin
        int c;
        while ((c = getchar()) != EOF) {
            if (c == '/') putchar('\\');
            else if (c == '\\') putchar('/');
            else putchar(c);

            if (c == sep_in) {
                putchar(sep_out);
            }
        }
    }

    return 0;
}

