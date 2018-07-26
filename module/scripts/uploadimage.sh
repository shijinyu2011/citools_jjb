#!/bin/bash

git clone ssh://xuhshen@hzgitv01.china.nsn-net.net:29418/citools/cciscript


git init trigger_repo
cd trigger_repo
git fetch git@gitlabe1.ext.net.nokia.com:ILCI/trigger.git master  && git checkout FETCH_HEAD
cd -

#tars="tars/statistics"
tars="tars"
echo "PARENT_URL=$PARENT_URL"
echo "GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION"
echo "JENKINS_URL=$JENKINS_URL"

new_imagename=" CIU_${{product}}_rcp-ci-r${{GERRIT_PATCHSET_REVISION}}_${{subsystem}}_watchdog-disabled"
if [ "`echo $product`" = "vRNC" ];then
   trigger='trigger_repo/cloudil/latest_ok_smoke_tested/cloudil_smk_ok_trigger.txt'
   image_path=`cat ${trigger}|grep -o "image_url=.*"|cut -d "=" -f2`
   image_pattern="CLOUD_IL_RNC.*-ci_.*qcow2"
else
   filename=`echo $product|tr A-Z a-z`
   trigger="https://svne1.isource.nokia.com/isource/svnroot/dmx-cruise-trig/RCP/rcp_common/2_latest_ok_smoke_tested"
   build_number=`svn cat --username hzci --password b2a6eefb --non-interactive --trust-server-cert ${{trigger}}/build_id_${{filename}}.txt|grep "BUILD_ID="|cut -d "=" -f2`
   image_path="http://10.56.118.71/pilivee/RCP/rcp_common/devel/${{build_number}}/images/"
   image_pattern="rcp.*ci.*qcow2"
fi
imagename=`curl ${{image_path}}|grep -o ${{image_pattern}}|cut -d ">" -f2`
echo "wget ${{image_path}}/${{imagename}} -q -O ${{new_imagename}}"
wget ${{image_path}}/${{imagename}} -q -O ${{new_imagename}}

chmod +x cciscript/image/image_patch.sh
echo "cciscript/image/image_patch.sh $new_imagename $tars"
./cciscript/image/image_patch.sh $new_imagename $tars
./cciscript/image/upimage.sh $new_imagename $new_imagename
#store image to folder for team debug
#mv -f  $new_imagename /home/CCI_IMAGE/
rm -fr *
