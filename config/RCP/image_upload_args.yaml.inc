- string:
   name: base_img
   description:  |
     "base runtime image for patching
      for example :http://rcp.dynamic.nsn-net.net/rcp/ci/73/cwlc/qemu/RCP_15.19.0-t04301122-ci.qcow2
     "
- string:
   name: vgp_package
   description: |
     "URL link or local dir for tar packages
      for example: http://hzwebserver02.china.nsn-net.net/tar/SS_RCPMsg/63/
     "
- string:
   name: target_image_name
   default: rcpci
- string:
   name: parent_buildnum
