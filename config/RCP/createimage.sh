#!/bin/bash
set -x
mkdir -p upload_content/baseimage upload_content/configs upload_content/git_repo_clones upload_content/packages/VGP_packages
cd upload_content/git_repo_clones
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/lcc_dib-utils -b VGPLCC_1.0 dib-utils
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/lcc_diskimage-builder -b VGPLCC_1.0 diskimage-builder
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/vgp_imagebuilder vgp_elements
git clone deveo@deveo.access.nsn.com:Nokia/projects/hello_prime/repositories/git/lcc_imagebuilder imagebuilder 

if test ! $base_img;then
    base_img=`cat RCP_CI_trigger/rcp_ci_trigger|grep "imageurl="|cut -d"=" -f2`
fi
echo "wget $base_img -q -O $WORKSPACE/upload_content/baseimage/vgp.qcow2"
wget $base_img -q -O $WORKSPACE/upload_content/baseimage/vgp.qcow2

echo export DIB_use_local_pip=True >$WORKSPACE/upload_content/configs/vgp_configrc
echo export PATH=/usr/local/bin:$PATH >>$WORKSPACE/upload_content/configs/vgp_configrc
echo export extra_args=-n,--image-cache=$WORKSPACE/.cache/imagebuild >>$WORKSPACE/upload_content/configs/vgp_configrc
echo modprobe loop >>$WORKSPACE/upload_content/configs/vgp_configrc
echo export DIB_NO_TMPFS=0 >>$WORKSPACE/upload_content/configs/vgp_configrc
echo export DIB_MIN_TMPFS=3 >>$WORKSPACE/upload_content/configs/vgp_configrc
#base image
echo export DIB_LOCAL_IMAGE=$WORKSPACE/upload_content/baseimage/vgp.qcow2 >>$WORKSPACE/upload_content/configs/vgp_configrc
#network tar
echo export DIB_VGP_PACKAGES_URL=$vgp_package >>$WORKSPACE/upload_content/configs/vgp_configrc

echo export DIB_IMAGE_SIZE=8 >>$WORKSPACE/upload_content/configs/vgp_configrc


date
#element list: vgp_local_packages, vgp_url_packages
$WORKSPACE/upload_content/git_repo_clones/imagebuilder/vm_image_builder/src/scripts/build_image.sh --name rcpci --build_root $WORKSPACE vgp_url_packages
date