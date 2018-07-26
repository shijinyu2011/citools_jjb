#!/bin/bash
target_image_name=${target_image_name//\//\_}
set -x
if test $parent_buildnum;then vgp_package="http://hzwebserver02.china.nsn-net.net/tar/SS_RCPMsg/$parent_buildnum";fi
if test ! $base_img;then 
   rm -fr rcp_ci_trigger
   svn export https://svne1.access.nsn.com/isource/svnroot/IPA_CI_triggers/RCP_CI_trigger/rcp_ci_trigger
   base_img=`cat rcp_ci_trigger|grep "imageurl="|cut -d"=" -f2`   
fi


mkdir -p upload_content/baseimage upload_content/configs upload_content/git_repo_clones upload_content/packages/VGP_packages
cd upload_content/git_repo_clones
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/lcc_dib-utils -b VGPLCC_1.0 dib-utils
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/lcc_diskimage-builder -b VGPLCC_1.0 diskimage-builder
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/vgp_imagebuilder vgp_elements
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/lcc_imagebuilder imagebuilder 

echo "wget $base_img -q -O $WORKSPACE/upload_content/baseimage/base.qcow2"
wget $base_img -q -O $WORKSPACE/upload_content/baseimage/base.qcow2

echo export DIB_use_local_pip=True >$WORKSPACE/upload_content/configs/vgp_configrc
echo export PATH=/usr/local/bin:$PATH >>$WORKSPACE/upload_content/configs/vgp_configrc
echo export extra_args=-n,--image-cache=$WORKSPACE/.cache/imagebuild >>$WORKSPACE/upload_content/configs/vgp_configrc
echo modprobe loop >>$WORKSPACE/upload_content/configs/vgp_configrc
echo export DIB_NO_TMPFS=0 >>$WORKSPACE/upload_content/configs/vgp_configrc
echo export DIB_MIN_TMPFS=2 >>$WORKSPACE/upload_content/configs/vgp_configrc
#base image
echo export DIB_LOCAL_IMAGE=$WORKSPACE/baseimage/base.qcow2 >>$WORKSPACE/upload_content/configs/vgp_configrc
#network tar
echo export DIB_VGP_PACKAGES_URL=$vgp_package >>$WORKSPACE/upload_content/configs/vgp_configrc
#echo export DIB_IMAGE_SIZE=8 >>$WORKSPACE/upload_content/configs/vgp_configrc


if `echo $vgp_package | grep -qi http` ; then 
  $WORKSPACE/upload_content/git_repo_clones/imagebuilder/vm_image_builder/src/scripts/build_image.sh --name $target_image_name --build_root $WORKSPACE vgp_url_packages
else 
  $WORKSPACE/upload_content/git_repo_clones/imagebuilder/vm_image_builder/src/scripts/build_image.sh --name $target_image_name --build_root $WORKSPACE vgp_local_packages
fi



## Upload to openstack cloud
git clone hzscm@hzling48.china.nsn-net.net:/linux_gerrit/gerrit/gitrepos/citools/cciscript.git
export image_name=$target_image_name
export image_path=$WORKSPACE/upload_content/built_img/$target_image_name.qcow2

for cert in `ls cciscript/admin_openrc*`;do
  source $cert
  for img in `glance image-list --name $image_name | grep bare |cut -d'|' -f2` ;do glance image-delete $img; done;
  glance image-create --name $image_name --disk-format=qcow2 --container-format=bare --is-public=True --file $image_path
done