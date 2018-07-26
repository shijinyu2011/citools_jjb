#!/bin/bash
unset https_proxy
unset http_proxy

if [ "`echo $GERRIT_BRANCH`" = "cloudVT" ];then
     if [ "`echo $label`" = "ILCCI" ];then
         exit 0
      fi
elif [ "`echo $GERRIT_BRANCH`" = "VirtualTrunk" ];then 
    if [ "`echo $label`" = "CLOUDCCI" ];then
      auth="--username hzci --password b2a6eefb --non-interactive --trust-server-cert "
      svn_url="http://svne1.access.nsn.com/isource/svnroot/scm_il/trunk/ipal-main-beta"
      if ! svn pg svn:externals $auth $svn_url |grep -q "$subsystem/" ; then 
          exit 0
      fi
    fi
fi

if test $GERRIT_REFSPEC;then refs=$GERRIT_REFSPEC;fi

rm -fr *
git init sad-runner
cd sad-runner
git fetch https://gitlabe1.ext.net.nokia.com/prime/sad-runner.git master  && git checkout FETCH_HEAD
cd -
#export STATIC_SCRIPT_ROOT=$(pwd)/sad-runner

git init cciscript
cd cciscript
git fetch ssh://xuhshen@gerrit.nsn-net.net:29418/citools/cciscript master && git checkout FETCH_HEAD
cd -

export dependency_env="SS_ILProduct SS_ILThirdpart"
export STATIC_SCRIPT_ROOT=$(pwd)/sad-runner

if [ "`echo $label`" = "CLOUDCCI" ];then
   workspace="/cci/test"
   mkdir -p $workspace
   export new_brc="branches/cloudVT"
else
   workspace="/var/fpwork/CCI/WS/test/test"
   export new_brc="branches/VirtualTrunk"
fi

mkdir -p $workspace/$EXECUTOR_NUMBER
logpath="$WORKSPACE/logs/"
mkdir -p $logpath
$WORKSPACE/cciscript/checkout/checkout_for_il.sh $subsystem $refs $VARENT $workspace/$EXECUTOR_NUMBER  $logpath

