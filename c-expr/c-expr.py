import os
import sys

source = "c-expr.c"
header = "c-expr.h" # custom, optional
binary = "c-expr"

coutformat = "%s | %g | %.17g | 0x%016llx | %.17g | %d"

def myexec(command):
    code = os.system(command)
    if os.WEXITSTATUS(code) != 0:
        print("errors running command "+command)
        sys.exit(1)    

def compute_c_expression(declarations,expressions) :
    # declarations is a list of declarations
    header_include = ''
    if os.path.isfile(header):
        header_include = f'#include "{header}"'
    with open(source,"w") as cfile:
        cfile.write(f"""
#include <stdio.h>
#include <math.h>
{header_include}
""")
        cfile.write(f"const char *pformat = \"{coutformat}\\n\";")        
        cfile.write("""
#define DOUBLE_2_HEX(lvalue)  ( *(unsigned long long int*) &(lvalue) )

void around(double v,double delta, int n) {
  DECLARE_PRIVATE();
  D(x,v);
  D(before_,v);
  D(_after_,v);
  DUMP(x);
  int i;
  for (i=1;i<=n;i++) {
     before_.value = nextafter(before_.value,before_.value-delta);
     printf("%2d | ",i);
     DUMP(before_);
  }
  for (i=1;i<=n;i++) {
     _after_.value = nextafter(_after_.value,_after_.value+delta);
     printf("%2d | ",i);
     DUMP(_after_);
  }
}

/* snippet from : https://stackoverflow.com/questions/33010010/how-to-generate-random-64-bit-unsigned-integer-in-c */
uint64_t mcg64(void)
{
    static uint64_t i = 1;
    return (i = (164603309694725029ull * i) % 14738995463583502973ull);
}

int main(int argc,char argv[]) {
""")
        cfile.write("""
   DECLARE_PRIVATE();
""")
                    
        for d in declarations:
#            if not d.endswith(";"):
#                d += ";"
            cfile.write("\t"+d+"\n")
        for e in expressions:
            cfile.write(f"\t_r = {e};\n")
            cfile.write(f"\t_m = frexp(_r,&_e);\n")
            cfile.write(f'\tprintf(pformat,"{e}",_r,_r,DOUBLE_2_HEX(_r), _m , _e );\n')
        cfile.write("\n}\n");

if len(sys.argv) == 1:
    cmd=sys.argv[0]
    print(f"""
SYNOPSIS:
    compute, execute and print a double expression using C language and <math.h> library

SINTAX:
    {cmd} <c-statement-1> <c-statement-2> ... <c-statement-n>

OUTPUT FORMAT:
    the printf output format of <c-espression> is:
    {coutformat}
    that is: 
    default precision | maximum precision | hex dump 64 bit | mantissa | exponent

EXAMPLES: 
    the command:
    {cmd} c-expr  "double max=1.79769313486231571e+308;" "double res = log2(2)/max;" "D(x,max); D(y,res);" "DUMP(x);DUMP(y);";

    will output:

x |g 1.79769e+308 1.7976931348623157e+308 0x7fefffffffffffff |m 0.99999999999999989 e 1024 | S=0 MANT=4503599627370495 0xfffffffffffff EXP=-2 0xfffe
y |g 5.56268e-309 5.5626846462680035e-309 0x0004000000000000 |m 0.5 e -1023 | S=0 MANT=1125899906842624 0x4000000000000 EXP=0 0x0

GENERATED FILES:

    after run, have a look at produced files:
    - {source} the source C file 
    - {binary} the binary file (can be executed again)
""")
    sys.exit(0)

dec = sys.argv[1:len(sys.argv)]
# print(f'end_decl={end_decl} start_expr={start_expr} le={le} args={dec} exp={exp} len=')

compute_c_expression( dec , [ ])

myexec(f'gcc -o {binary} {source} -lm')
myexec(f'./{binary}')


      
