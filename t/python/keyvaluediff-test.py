import os
import sys
import logging

pegasoroot =  os.getenv('PEGASO_ROOT')
libdirname = os.path.join(pegasoroot,'lib/python')
sys.path.append(libdirname)

from keyvaluediff import KVSet

logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.DEBUG)

rTEST= r'HWTEST_\d\d\d'
rREQ=r'HW_S?REQ_\d\d\d\d'

superset = []

for f in [('DIRECT','kvdiff-direct.CSV',True,rTEST,rREQ),
          ('INVERSE','kvdiff-inverse.CSV',True,rREQ,rTEST),
          ('TEST','kvdiff-test.CSV' , False, rTEST,rREQ),
          ('ANNEX1','kvdiff-annex.CSV', True, rREQ, rTEST)
]:
    s = KVSet(f[0],os.path.join(pegasoroot ,'t/python/data',f[1]), ',' , f[3] , f[4] , f[2] )
    s.load()
    s.process()
    # s.dump()
    superset.append(s)
    inv = s.invert()
    inv.process()
    # inv.dump()
    superset.append(inv)


# superset[0].compare(superset[4],"primo")
superset[4].compare(superset[0])

superset[1].compare(superset[2])    
superset[0].compare(superset[3])

superset[5].compare(superset[2])
superset[2].compare(superset[5])

superset[3].compare(superset[4])

superset[6].compare(superset[2])

superset[6].compare(superset[5])

superset[7].compare(superset[4])


superset[0].dump_keys_to_file("tests")
superset[2].dump_keys_to_file("req")


