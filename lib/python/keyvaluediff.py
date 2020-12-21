import re
import os
import logging
import csv

from inspect import getmembers
from pprint import pprint

def ddd(x):
    # pprint(getmembers(x))
    pprint(x,depth=1)

def var_dump(var, prefix=''):
    """
    You know you're a php developer when the first thing you ask for
    when learning a new language is 'Where's var_dump?????'
    """
    my_type = '[' + var.__class__.__name__ + '(' + str(len(var)) + ')]:'
    print(prefix, my_type, sep='')
    prefix += '    '
    for i in var:
        if type(i) in (list, tuple, dict, set):
            var_dump(i, prefix)
        else:
            if isinstance(var, dict):
                print(prefix, i, ': (', var[i].__class__.__name__, ') ', var[i], sep='')
            else:
                print(prefix, '(', i.__class__.__name__, ') ', i, sep='')


class Errors:
    def __init__(self):
        self.err = {}
        pass

    def add(self,code,error):        
        if code in self.err:
            self.err[code].append(error)
        else:
            self.err[code] = [error]
        pass

    def add_list(self,code,error_list):
        for e in error_list:
            self.add(code,e)
        pass
    
    # error_obj is another Error() class 
    def extend(self,error_obj):
        for code in error_obj.err.keys():
            if code in self.err:
                self.err[code].extend( error_obj.err[code] )
            else:
                self.err[code] = error_obj.err[code]
        pass

    def log(self,msg=None):
        if msg is not None:
            logging.info(msg)
        for code in self.err.keys():
            for e in self.err[code]:
                logging.error('<{0}>: {1}'.format(code,e))
        pass
    
    def log_by_group(self,regex,msg):
        groups = {} # hash of Errors
        for code in self.err.keys():
            s_Obj = re.search( regex, code, re.M|re.I)
            if s_Obj: 
                partition = s_Obj.group()
            else:
                partition = ''
            if partition not in groups:
                e = Errors()
                e.add_list(code,self.err[code])
                groups[partition] = e
            else:
                groups[partition].add_list(code,self.err[code])
                
        for g in groups.keys():
            logging.info("log_by_group "+msg+" PARTITION= '{0}' ".format(g))
            groups[g].log()
        pass
                
class KVSet:
    def __init__(self,name,filename,separator,regex_k,regex_v,duplicated_keys = True):
        self.name = name
        self.regex_k = regex_k
        self.regex_v = regex_v
        self.regex_c_k = re.compile( regex_k )
        self.regex_c_v = re.compile( regex_v )
        self.separator = separator
        self.data = {}
        self.data_uniq = {}
        self.duplicated_keys = duplicated_keys
        self.filename = filename
        # dict of list of errors
        self.keys_with_errors = Errors()
        self.values_with_errors = Errors()
        # self.load(filename,duplicated_keys)

    def trace_error(self,error,key,value=None):
        logging.error(error)        
        self.keys_with_errors.add(key,error)
        if value is not None:
            self.values_with_errors.add(value,error)
        pass

    def return_all_errors(self):
        all_err = Errors()
        all_err.extend(self.keys_with_errors)
        all_err.extend(self.values_with_errors)
        return all_err
        pass
        
    def remove(self,keys):
        for k in keys:
            try:
                del self.data[k]
                if k in self.data_uniq:
                    del self.data_uniq[k]
            except KeyError:
                logging.error("{0}: cannot remove '{1}'".format(self.name,k))
            else:
                logging.info("{0}: removed '{1}'".format(self.name,k))
            pass
        pass

    
    def show_error(self,error,key,value=None):
        full_error = error
        if key in self.keys_with_errors.err:
            # add additional traced errors:
            logging.warning(error+" (TRACED errors:" + "|".join(self.keys_with_errors.err[key]) + ")")
        else:
            # logging.error(error)
            self.trace_error(error,key,value)
        pass
    
    def load(self):
        logging.info("loading {0} from file {1} ...".format(self.name,self.filename))
        with open(self.filename, newline='') as csvfile:
            reader = csv.DictReader(csvfile, delimiter=';' )
            self.fieldnames = reader.fieldnames
            #            print (self.fieldnames,vars(self.fieldnames))
            i=1
            logging.info("fields: " + ",".join(self.fieldnames))
            for row in reader:
                i+=1
                k = row[self.fieldnames[0]]
                k = k.strip()
                if not bool(self.regex_c_k.fullmatch(k)) :
                    self.trace_error('{2}: key \'{0}\' regex error at line \'{1}\''.format(k,i,self.name),k)
                if len(self.fieldnames)>1:
                    v = re.split('\s*'+self.separator+'\s*', row[self.fieldnames[1]].strip() )
                else:
                    v = []
            
                if len(v) > 1 and v[len(v)-1]=='':
                    # a separator was present at the end, we can tolerate that
                    logging.warning("{2}: key '{0}' there is a separator '{1}' at the end of values, ignored".format(k,self.separator,self.name))
                    v.pop()
                for item in v:
                    if not bool(self.regex_c_v.fullmatch(item)):
                        self.trace_error("{3}: key '{0}' value '{1}' regex error at line '{2}'".format(k,item,i,self.name),k,item)
                # manage duplicates:
                if k in self.data:
                    if not self.duplicated_keys:
                        self.trace_error("{2}: key {0} duplicated at line {1} ".format(k,i,self.name),k)
                    self.data[k].extend(v)
                else:
                    self.data[k] = v
                # print(row[self.fieldnames[0]], row[self.fieldnames[1] ])
                # print(k)
            pass
        logging.info("loaded {0}".format(len(self.data)))
        pass
        


    def check_duplicates(self):                
        for k in self.data.keys():
            v = self.data[k]
#            logging.info("k={}".format(k))
#            ddd(v)
#            logging.info(v)
            seen_v = set()
            uniq_v = []
            for x in v:
                if x not in seen_v:
                    uniq_v.append(x)
                    seen_v.add(x)
                else:
                    self.trace_error("{2}: key '{0}' has duplicated value '{1}'".format(k,x,self.name),k,x)
            self.data_uniq[k] = sorted(uniq_v)

    def process(self):
        self.check_duplicates()

    def dump(self):
        logging.info("==== DUMP OF {0} ==== file: {1}".format(self.name,self.filename))
        for k in sorted(self.data_uniq.keys()):
            logging.info("{0} --> {1}".format(k, ", ".join(self.data_uniq[k])))
        pass

    def dump_keys_to_file(self,ofile):
        file_k = ofile+"_keys.out";
        fk = open(file_k, "w")
        for k in sorted(self.data_uniq.keys()):
            fk.write(f'{k}\n')
            pass
        fk.close()
        pass
    
    def invert(self):
        # return a KVSet object as inverse matrix:
        inv = KVSet("INVERSE("+self.name+")",self.filename,self.separator,
                    self.regex_k , self.regex_v,self.duplicated_keys)
        for k in self.data_uniq.keys():
            for vv in self.data_uniq[k]:
                if vv in inv.data:
                    inv.data[vv].append(k)
                else:
                    inv.data[vv] = [k];
        return inv

    def compare(self,other,msg="",keys_only=False,say_both = False):
        allkeys = {}
        logging.info("===== DIFF {2}: {0} vs {1} ====".format(self.name,other.name,msg))
        for k in self.data.keys():
            allkeys[k]='<'
        for k in other.data.keys():
            if k in allkeys:
                allkeys[k]='-'
            else:
                allkeys[k]='>'

        # pprint(allkeys)
                
        for k in sorted(allkeys):
            if allkeys[k]=='<':
                self.show_error("key {0} present in '{1}' , missed in '{2}'".format(k,self.name,other.name),k)
            if allkeys[k]=='>':
                self.show_error("key {0} missed  in '{1}' , present in '{2}'".format(k,self.name,other.name),k)
            if allkeys[k]=='-':
                if say_both:
                    logging.info("{0} --> present in both, ok".format(k))
                if keys_only:
                    continue
                i1=0
                i2=0
                v1=sorted(self.data[k])
                v2=sorted(other.data[k])
                while i1<len(v1) and i2<len(v2):
                    if(v1[i1] == v2[i2]):
                        if say_both:
                            logging.info("key {0} : {1} present in both, ok".format(k,v1[i1]))
                        i1+=1
                        i2+=1
                    elif (v1[i1] < v2[i2]):
                        self.show_error("key {0} : {1} present in '{2}' , missed in '{3}'".format(k,v1[i1],self.name,other.name),k,v1[i1])
                        i1+=1
                    elif(v1[i1] > v2[i2]):
                        self.show_error("key {0} : {1} missed in '{2}' , present in '{3}'".format(k,v2[i2],self.name,other.name),k,v2[i2])
                        i2+=1                              
                    pass
                
                if(i1<len(v1)):
                    while i1<len(v1):
                        self.show_error("key {0} : {1} present in '{2}', missed in '{3}'".format(k,v1[i1],self.name,other.name),k,v1[i1])
                        i1+=1
                if(i2<len(v2)):
                    while i2<len(v2):
                        self.show_error("key {0} : {1} missed in '{2}' , present in '{3}'".format(k,v2[i2],self.name,other.name),k,v2[i2])
                        i2+=1
                pass
        
