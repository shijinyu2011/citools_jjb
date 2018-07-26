#!/bin/bash

wkdir=sandbox

if [ "`echo {product}`" = "vRNC" ];then
   export PRODUCT=vRNC
   checkout_product=vrnc
   svnenv="./product/build/svnenv.sh -p vrnc"
   utresult_folder="./product/build"
else
   export PRODUCT=common
   checkout_product=rcp
   svnenv="./flexiserver/build/svnenv.sh -p common"
   utresult_folder="./flexiserver/build"
fi

echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
echo "`date`:################get ci scripot#########################"
rm -rf cciscript
git clone ssh://hzci@hzgitv01.china.nsn-net.net:29418/citools/cciscript -b master --depth 1

echo "`date`:###############checkout source code#######################"
dep=`cat cciscript/checkout/dep.config|grep "$subsystem:"|cut -d ":" -f2`
ft_dep=`cat cciscript/checkout/dep_ft.config|grep "$subsystem:"|cut -d ':' -f2|tr " " ","`
python cciscript/checkout/checkout.py -s $subsystem,$dep,$ft_dep -f $GERRIT_REFSPEC -d $WORKSPACE/$wkdir -p $checkout_product

#workaroud for SCM
sed -i '/unlink/d' $WORKSPACE/$wkdir/flexiserver/build/svnenv.sh
if [ "$subsystem" == "rcppmuploader" ]; then pushd $WORKSPACE/$wkdir/rcppmuploadercmapi;../flexiserver/build/svnenv.sh -j "make;make install";popd; fi;
if [ "$subsystem" == "SS_RCPNETSNMP" ]; then ln -fs $WORKSPACE/$wkdir/SS_RCPNETSNMP $WORKSPACE/$wkdir/SS_NetSnmp; fi;
if [ "$subsystem" == "SS_RCPCCSRT" ]; then pushd $WORKSPACE/$wkdir/gerrit_code/SS_RCPCCSRT; ln -fs $WORKSPACE/$wkdir/SS_DPDK SS_DPDK;popd; fi;
if [ "$subsystem" == "RCPNetworkManager" ]; then pushd $WORKSPACE/$wkdir;git clone ssh://git@hzgitv01.china.nsn-net.net:29418/scm_rcp/RCPNetworkManager.git -b rcptrunk --depth 1;popd; fi;

  export PATH=$PATH:/usr/bin/
  svn export --force http://svne1.access.nsn.com/isource/svnroot/SS_ILThirdpart/branches/rcptrunk/SS_ILThirdpart/tnsdlunit sandbox/SS_ILThirdpart/tnsdlunit
  svn export --force http://svne1.access.nsn.com/isource/svnroot/SS_ILThirdpart/branches/rcptrunk/SS_ILThirdpart/cpputest/ sandbox/SS_ILThirdpart/cpputest/
  svn export --force http://svne1.access.nsn.com/isource/svnroot/SS_ILThirdpart/branches/rcptrunk/SS_ILThirdpart/lcov-1.11 sandbox/SS_ILThirdpart/lcov-1.11


echo "`date`:############### staring ..... ##################################"
git clone https://gitlabe1.ext.net.nokia.com/prime/sad-runner.git -b master --depth 1

export V=t
export PATH=$PATH:/apps/klocwork/bin
python $WORKSPACE/sad-runner/sad_runner.py -p cloudil -m $subsystem -b $WORKSPACE/$wkdir/$subsystem -o $WORKSPACE/statistics

cat $WORKSPACE/statistics/ut.log|grep ": \*\*\*" && exit 1
cat $WORKSPACE/$wkdir/$utresult_folder/TESTS-TestSuites.xml|grep -E "(errors=\"|failures=\"|FailuresTotal>|Errors>)[1-9]+" && exit 1
echo "utest sucessful!"
