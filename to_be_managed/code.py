import string
import os
import basen
import sys


# italian spelling alphabet
# only * are choosen due non confusing with other letters/digits:
# A	Ancona *
# B	Bologna	 * 
# C	Como	 * 
# D	Domodossola * 	
# E	Empoli	 *
# F	Firenze	 * 
# G	Genova	
# H	Hotel	*
# I	Imola	 
# J	Jolly	
# K	Kursaal	* 
# L	Livorno	*
# M	Milano	*
# N	Napoli	*
# O	Otranto	 
# P	Padova	 *
# Q	Quarto	 
# R	Roma	 *
# S	Savona	 * 
# T	Torino	* 
# U	Udine	 * 
# V	Venezia	 *
# W	Washington * 
# X	Xeres	*
# Y	Yacht	 *
# Z	Zara	*

# PRIME NUMBER SEARCH DB:
# http://compoasso.free.fr/primelistweb/page/prime/liste_online_en.php


def db_add(d,key):
    if key in d:
        d[key]+=1
        # comment out this assert is an alternative
        # of the external usage of occurrence_int.c 
        # assert False, f'duplicated value: {key}'        
    else:
        d[key]=1
    pass

def code2str(coded):
    return "".join(coded)

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

class CodeException(Exception):
    def __init__(self,caller_class,msg):
        super().__init__(caller_class.name() + " |> " + msg)         
    pass

class CodeException_InconsistentState(CodeException):
    pass

class CodeException_InputError(CodeException):
    pass

class CodeException_TestError(CodeException):
    pass

    
    
class CodeBase: # a base class for a generic coder
    def configure(self):
        # shall be called by __init__ subclasses 
        self.LLETTERS=len(self.LETTERS)
        self.ZEROLETTER=self.LETTERS[0]
        # prime number shall be p=4 (mod 3)
        r = self.LAST_PRIME % 4
        if r!=3 :
            raise CodeException_InconsistentState(self, "prime:{0} reminder (mod 4) != 3 : {1}".format(self.LAST_PRIME,r))
        # pre calculate needed NLETTERS powers:
        self.NLETTERS = []
        for power in range(0,self.MAX_NLETTERS+1):
            self.NLETTERS.append (self.LLETTERS ** (power))
        self.configured = True
        # print("NLETTERS:",self.NLETTERS)
        pass


    def name(self):
        return self.__class__.__name__
                                             
    def __init__(self):
        self.LETTERS = 'ABCDEFHKLMNPRSTUVWXYZ'
        # as a conseguence of LETTERS we have:        
        # shall be defined in subclasses:
        self.MAX = 0
        self.LAST_PRIME = 0
        # number of permutations. 0 means no permutatation,
        # so is the identity function:
        self.PERMUTE_N = 0
        # pre-calculated powers of letters based strings, for
        # best performance.
        # the index is the power. we init here as empty list
        # shall be set in subclasses
        # maximum power of continuous LETTERS used into pattern
        self.MAX_NLETTERS = 0
        self.configured = False

    def raise_condition(valuestr,value,operator,maxvaluestr,maxvalue):
        raise CodeException_InputError(self,f"error condition: {valuestr}={value} {operator} {maxvaluestr}={maxvalue}")
        pass

    def check_residual(v,m):
        if v >= m:
            self.raise_condition("residual value",v,
                                 ">=",
                                 "nletters",m)
        pass
        
    # pad a string coded as letter s, group of pad number n
    # the "zero" letter is used to pad
    def pad_zeroletter(self,s,n):
        ret = s
        if(len(s) < n): # add zero pad:
            ret=self.ZEROLETTER * ( n-len(s) ) + s
        return ret

# snippet from:
# http://preshing.com/20121224/how-to-generate-a-sequence-of-unique-random-integers/
# C++ code:
# unsigned int permuteQPR(unsigned int x)
# {
#     static const unsigned int prime = 4294967291;
#     if (x >= prime)
#         return x;  // The 5 integers out of range are mapped to themselves.
#     unsigned int residue = ((unsigned long long) x * x) % prime;
#     return (x <= prime / 2) ? residue : prime - residue;
# }
    # define permutation function.
    def permute(self,x : int):
        if x>self.MAX:
            self.raise_condition("permute x",x,">","MAX",self.MAX)
        if (x >= self.LAST_PRIME):
            # The integers out of range are mapped to themselves:
            return x;
        residue = x*x % self.LAST_PRIME
        if x <= self.LAST_PRIME//2:
            return residue
        return self.LAST_PRIME-residue

    def permute_n(self,x:int):
        res = x
        if self.PERMUTE_N == 0:
            return res
        for i in range(0,self.PERMUTE_N):
            res = self.permute(res)
        return res

    # code the number i as n-length LETTERS alphabet
    def code_letters(self,i : int,n : int):
        return self.pad_zeroletter ( basen.int2base( i, self.LETTERS) , n)

    # decode the string s as LETTERS alphabet
    def decode_letters(self,s):
        return basen.base2int( s, self.LETTERS)

    # full test of functions
    # write output on stderr
    # and write on stdout numbers to be given to "/occurence_int.c"
    # executable
    def test_range_permute(self,start:int = 0, step:int = 1,limit:int = 0):
        if limit == 0:
            limit = self.MAX
        # db_coded = { }
        db_n = {}
        eprint("start {} step {} limit {}".format(start,step,limit))
        # with os.fdopen(3, 'w') as checkfile:
        for i in range(start,limit,step):
                c0 = self.encode(i)            
                p2 = self.permute_n(i)
                c2 = self.encode(p2)
                db_add(db_n,p2)
                # db_add(db_coded,code2str(c2))
                d0 = self.decode(c0)
                d2 = self.decode(c2)
                print(p2)
                eprint(self.__class__.__name__ , i,c0,p2,c2)
                
                if d0 != i:
                    raise CodeException_TestError(self,f"d0 error check d0:{d0} vs i:{i}")
                if d2 != p2:
                    raise CodeException_TestError(self,f"p2 error check d2:{d2} vs p2:{p2}")

    # code a digit interget to be padded as lenght 'pad'
    # note: this is a static function (no use of 'self')
    def code_int(i: int, pad: int):
        # format integer
        f = "%0" + str(pad) + "d" 
        return str(f % (i))

class AA999ZZ(CodeBase):
    def __init__(self):
        super().__init__()
        # 21^2 * 10^2 * 21^2 = 19448100 
        self.MAX = 19448100
        self.LAST_PRIME = 19447919
        self.PERMUTE_N = 2
        self.MAX_NLETTERS = 2
        self.configure() # shall be called at last
        
    def encode(self,i:int):
        left = i
        nletters = self.NLETTERS[2]
        
        p1 = self.code_letters( left % nletters , 2)
        left //= nletters;

        p2 = CodeBase.code_int( left % 1000, 3)
        left //= 1000

        # left shall be < nletters already! to be asserted
        if left >= nletters:
            dddddd
        p3 = self.code_letters ( left, 2 )

        return [p3,p2,p1]

    def decode(self,coded):
        # less significant first, ZZ
        res = self.decode_letters(coded[2] );
        # numeric:
        nletters = self.NLETTERS[2]
        res += int(coded[1]) * nletters
        res += self.decode_letters(coded[0] ) * nletters * 1000 ;
        return res
    
class AA999888(CodeBase):
    def __init__(self):
        super().__init__()
        # 21^2 * 10^3 * 10^3 = 13230000, 
        self.MAX        = 441000000 
        self.LAST_PRIME = 440999983
        self.PERMUTE_N  = 2
        self.MAX_NLETTERS= 2
        self.configure() # shall be called at last
        
    def encode(self,i:int):
        left = i;
        nletters = self.NLETTERS[2]
        
        p1 = CodeBase.code_int( left % 1000, 3) 
        left = left // 1000
        
        p2 = CodeBase.code_int (left % 1000, 3 )
        left = left // 1000

        # left shall be < nletters already! to be asserted
        CodeBase.check_residual(left,nletters);
        
        p3 = self.code_letters( left, 2)
        
        return [p3,p2,p1]

    def decode(self,coded):
        # start less significant part:
        res = int(coded[2])
        res += int(coded[1]) * 1000
        res += self.decode_letters(coded[0] ) * 1000000
        return res
        
class A99(CodeBase):
    def __init__(self):
        super().__init__()
        # 21^1 * 100
        self.MAX        = 2100
        self.LAST_PRIME = 2099
        self.PERMUTE_N  = 2
        self.MAX_NLETTERS = 1
        self.configure() # shall be called at last

    def encode(self,i:int):
        left = i
        nletters = self.NLETTER[1]

        p1 = CodeBase.code_int( left % 100, 2)
        # left shall be < nletters already! to be asserted
        left //= 100

        CodeBase.check_residual(left,nletters)
            
        p2 = self.code_letters( left, 1)
        return [p2,p1]
        
    def decode(self,coded):
        res = int(coded[1])
        res += self.decode_letters(coded[0] ) * 100
        return res

class AA99(CodeBase):
    def __init__(self):
        super().__init__()
        # 21^2 * 100
        self.MAX        = 44100
        self.LAST_PRIME = 44087
        self.PERMUTE_N  = 0
        self.MAX_NLETTERS = 2
        self.configure() # shall be called at last

    def encode(self,i:int):
        left = i
        nletters = self.NLETTERS[2]

        p1 = CodeBase.code_int( left % 100, 2)
        left //= 100
        # left shall be < nletters already! to be asserted
        CodeBase.check_residual(left,nletters)
        
        p2 = self.code_letters( left, 2)
        return [p2,p1]
        
    def decode(self,coded):
        res = int(coded[1])
        res += self.decode_letters(coded[0] ) * 100
        return res
    
class AA99ZZ(CodeBase):
    def __init__(self):
        super().__init__()
        # 21^2 * 1000
        self.MAX        = 19448100 
        self.LAST_PRIME = 19448059
        self.PERMUTE_N  = 2
        self.MAX_NLETTERS = 2
        self.configure()

    def encode(self,i:int):
        left = i
        
        p1 = self.code_letters( left % self.NLETTERS[2] , 2)
        left //= self.NLETTERS[2]

        p2 = CodeBase.code_int( left % 100, 2)
        left //= 100

        CodeBase.check_residual(left,self.NLETTERS[2] )

        p3 = self.code_letters( left, 2)
        return [p3,p2,p1]
        
    def decode(self,coded):
        res = self.decode_letters(coded[2] )
        power =  self.NLETTERS[2]
        
        res += int(coded[1]) * power
        power *= 100
        
        res += self.decode_letters(coded[0] ) * power
        return res
    
class AAA999(CodeBase):
    def __init__(self):
        super().__init__()
        # 21^3 * 1000
        self.MAX        = 9261000
        self.LAST_PRIME = 9260963
        self.PERMUTE_N  = 3
        self.MAX_NLETTERS = 3
        self.configure()

    def encode(self,i:int):
        left = i
        p1 = CodeBase.code_int( left % 1000, 3)
        left //= 1000
        CodeBase.check_residual(left,self.NLETTERS[3])            
        p2 = self.code_letters( left , 3)
        return [p2,p1]
        
    def decode(self,coded):
        res = int(coded[1])
        res += self.decode_letters(coded[0] ) * 1000
        return res





if __name__ == "__main__":
    
    pattern_list = {
        'AA999ZZ'  :  AA999ZZ() ,
        'AA999888' :  AA999888() ,
        'AA99'     :  AA99() ,
        'AA99ZZ'   :  AA99ZZ(),
        'AAA999'   :  AAA999()
    }
    
    if(len(sys.argv) != 2):
        eprint('param error: patterna missed; valid values are:',pattern_list.keys())
    else:
        pattern = sys.argv[1]
        if pattern in pattern_list:
            pattern_list[pattern].test_range_permute(0,1)
        else:
            eprint("bad pattern: ",pattern)
            pass
    pass






