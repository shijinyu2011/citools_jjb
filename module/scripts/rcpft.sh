#/bin/bash
git clone ssh://xuhshen@hzgitv01.china.nsn-net.net:29418/citools/cciscript
if test $GERRIT_TOPIC;then mkdir rcpci; cp -r cciscript/ft/workaround_for_feature_branch rcpci/rfcli_output;exit 0;fi;
chmod +x ./cciscript/ft/rcpft.sh
GLANCE_PATTERN=${{product}}_rcp-ci-r${{GERRIT_PATCHSET_REVISION}}_${{subsystem}}
echo "GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION"
echo "GLANCE_PATTERN=$GLANCE_PATTERN"
./cciscript/ft/rcpft.sh  $product $GLANCE_PATTERN $subsystem

