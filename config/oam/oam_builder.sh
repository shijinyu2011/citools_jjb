#!/bin/bash
echo SVN_REV=$SVN_REVISION> $WORKSPACE/build_revision.txt
echo CCI_TRIGGER={cci_trigger}>>$WORKSPACE/build_revision.txt
echo SMT_TRIGGER={smt_trigger}>>$WORKSPACE/build_revision.txt
if [ "$GERRIT_REFSPEC" != "" ]; then 
  rm -rf {repo} build_revision.txt
  git clone $GERRIT_SCHEME://hzci@$GERRIT_HOST:$GERRIT_PORT/$GERRIT_PROJECT -b $GERRIT_BRANCH --depth 1 {repo}
  cd  {repo}
  git fetch $GERRIT_SCHEME://hzci@$GERRIT_HOST:$GERRIT_PORT/$GERRIT_PROJECT $GERRIT_REFSPEC && git checkout FETCH_HEAD
  cd ..
  if [ {MODULE} = "foolib" ]; then 
      svn co http://bescme.inside.nsn.com/isource/svnroot/ipa_tools/py_sack_tools/trunk/src@2097 {repo}/src/py_sack_tools
  fi
  export SAVE_TO_SAD=N
fi

#find repo/PAC -name *.PAC |xargs sed -i '/lint\.com/d'
#find repo/src -name *.com |xargs sed -i '/lint\.com/d'
if [ -f {repo}/PAC/{PAC} ];then
  mv {repo}/PAC/{PAC} {repo}/PAC/{PAC}.ORG
  sed '/lint\.com/d' {repo}/PAC/{PAC}.ORG > {repo}/PAC/{PAC}
fi
if [ -f {repo}/{com} ]; then 
  mv {repo}/{com} {repo}/{com}.org
  sed '/lint\.com/d' {repo}/{com}.org > {repo}/{com}
fi
if [ $PRODUCT = crnc ] && [ $V = m ];then
  export V=c
  export mt=1
  sed -i 's/wnt/wnt -goto mt/' {repo}/PAC/Makefile
fi

unset SVN_VERSION
export PATH=$PATH:/apps/klocwork/bin:/opt/bin
source /linux_builds/linuxsacktools/linsee/python_2.7.2/interface/startup/python_2.7.2.env
source /linux_builds/linuxsacktools/linsee/python_2.7.2p2/interface/startup/xpython2.7.2p2.env
source /linux_builds/linuxsacktools/linsee/python_2.7.2p3/interface/startup/xpython2.7.2p3.env
source /opt/svn/linux64/ix86/svn_1.7.8/interface/startup/svn_1.7.8_64.env

if [ $PRODUCT = crnc ] && [ $V = c ];then 
  export TNCHECK_WORK_DIR={TNCHECK_DIR}
elif [ $PRODUCT = mcrnc ] && [ $V = c ];then 
  export TNCHECK_WORK_DIR=src
fi

mkdir -p statistics/
echo "" >statistics/crnc_prb_compile.log
if test -d sad-runner;
then
  git --git-dir=./sad-runner/.git  pull origin refs/heads/master
else
  git clone https://gitlabe1.ext.net.nokia.com/prime/sad-runner.git -b master --depth 1 sad-runner
fi

if [ "$SACK" = "None" ];then
  python sad-runner/sad_runner.py -p {PROJECT} -m {SAD_MODULE} -b $WORKSPACE/{repo} -o $WORKSPACE/statistics -x {PAC}
else
  python sad-runner/sad_runner.py -p {PROJECT} -m {SAD_MODULE} -b $WORKSPACE/{repo} -o $WORKSPACE/statistics --branch {BRANCH} --sack {SACK} --product {PRODUCT_NAME} -x {PAC}
fi
ret=$?

if [ $PRODUCT = crnc ] && [ "$mt" = "1" ];then
  echo "no zip" 
#  zip -j $WORKSPACE/cov_files.zip $WORKSPACE/repo/*.bra $WORKSPACE/repo/tncov.ord;
fi
exit $ret

