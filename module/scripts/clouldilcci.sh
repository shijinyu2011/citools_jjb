#!/bin/bash

wkdir=sandbox

export PRODUCT=vRNC
checkout_product=vrnc
svnenv="./product/build/svnenv.sh -p vrnc"

echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
echo "`date`:################get ci scripot#########################"
rm -rf cciscript
git clone ssh://hzci@hzgitv01.china.nsn-net.net:29418/citools/cciscript -b master --depth 1

echo "`date`:###############checkout source code#######################"
dep=`cat cciscript/checkout/dep.config|grep "$subsystem:"|cut -d ":" -f2`
ft_dep=`cat cciscript/checkout/dep_ft.config|grep "$subsystem:"|cut -d ':' -f2|tr " " ","`
python cciscript/checkout/checkout.py -s $subsystem,$dep,$ft_dep -f $GERRIT_REFSPEC -d $WORKSPACE/$wkdir -p $checkout_product
#workaroud for SCM
if [ "{v}" == "t" ]; then
  export PATH=$PATH:/usr/bin/
  svn export --force http://svne1.access.nsn.com/isource/svnroot/SS_ILThirdpart/branches/rcptrunk/SS_ILThirdpart/tnsdlunit sandbox/SS_ILThirdpart/tnsdlunit
  svn export --force http://svne1.access.nsn.com/isource/svnroot/SS_ILThirdpart/branches/rcptrunk/SS_ILThirdpart/cpputest/ sandbox/SS_ILThirdpart/cpputest/
  svn export --force http://svne1.access.nsn.com/isource/svnroot/SS_ILThirdpart/branches/rcptrunk/SS_ILThirdpart/lcov-1.11 sandbox/SS_ILThirdpart/lcov-1.11
fi
echo "`date`:############### staring ..... ##################################"
mkdir -p $WORKSPACE/statistics
pushd $WORKSPACE/$wkdir/
$svnenv -j "cd $subsystem/build;make rpm_ft" > $WORKSPACE/statistics/compile.log
mv $subsystem/build/*.tar.xz $WORKSPACE/statistics/
popd
for i in `cat cciscript/checkout/dep_ft.config|grep "$subsystem:"|cut -d ':' -f2`;do 
  pushd $WORKSPACE/$wkdir/
   $svnenv -j "cd $i/build;make rpm_ft" >> $WORKSPACE/statistics/compile.log 2>&1
  mv $i/build/*.tar.xz $WORKSPACE/statistics/
  popd
done
cat $WORKSPACE/statistics/compile.log|grep ": \*\*\*" && exit 1

