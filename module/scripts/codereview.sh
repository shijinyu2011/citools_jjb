#!/bin/bash
#patchset=00c6c740f9492c141e9f2348f4b07718535cc298
echo $GERRIT_PATCHSET_REVISION
echo $GRADE
echo "ssh -p 29418 hzci@hzgitv01.china.nsn-net.net gerrit review --code-review $GRADE $GERRIT_PATCHSET_REVISION"
ssh -p 29418 hzci@hzgitv01.china.nsn-net.net gerrit review --code-review $GRADE $GERRIT_PATCHSET_REVISION

