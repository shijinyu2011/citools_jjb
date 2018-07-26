#!/bin/bash
#./init.sh -c conf/jenkins_new.ini -m conf/commonil.conf -p common  -s "_GIT"
#./init -p vrnc -m moudules -f rcp/compile.yaml
#./init.sh -c conf/jenkins_new.ini -m conf/commonil.conf -s "_GIT"
product=vRNC
module=config/rcp_modules
yaml_file="yamls/rcp/rcp_compile.yaml"
#jenkins job build configure
jjb="/usr/local/bin/jenkins-jobs"
jjb_configure_file="conf/jenkins.ini"
Test=false

group_list="all no_ut no_ft no_ut_ft"
product_list="ilvrnc vRNC LA cWLC cBTS common"

product_file="product.yaml.inc"
group_file="group.yaml.inc"

help()
{
  echo "usage: init  [-p <projectname>] [-m <configure file>] [-f <yaml file> ] [-j <jjb tool path>] [-c <jjb cobfigure file> ] [-t]"
  echo "  -p  projectname,for example:$product_list,default is vRNC"
  echo "  -m  configure file to configure the jenkins jobs,default is rcp_modules"
  echo "  -f  yaml files,default is yamls/rcp/rcp_compile.yaml"
  echo "  -g  jenkins job group ,only support $group_list "
  echo "  -s  special jenkins job fingerprint "
  echo "  -j  jjb tool path,default is /usr/local/bin/jenkins-jobs"
  echo "  -c  jjb configure file,default is /home/eclipse/sxh/temp/jenkins-job-builder/etc/jenkins_jobs1.ini"
  echo "  -a  used to create specfic subsystem jobs"
  echo "  -t  used to run test job, default is false,if added this arg,it will run test instead of configure the jobs"
  echo "  -h  helper"
}

checkargs()
{
 for i in `echo $1`;do
   if [ "$i" = "$2" ];then
    return 0
   fi
 done
 echo "error: only \"$1\" are supported for \"$3\" "
 exit 1
}

while getopts "p:m:f:j:c:g:s:a:th" arg
do
   case $arg in
        p)
          product=$OPTARG
          checkargs "$product_list" "$product" "-p"         
          ;;
        m)
          module=$OPTARG
          ;;
        f)
          yaml_file=$OPTARG
          ;;
        g)
          group=$OPTARG
          checkargs "$group_list" "$group" "-g"
          ;;
        j)
          jjb=$OPTARG
          ;;
        c)
          jjb_configure_file=$OPTARG
          ;;
        s)special_job=$OPTARG
          ;;
        a) special_subsystem=$OPTARG
          ;;
        t)Test=true
          ;;
        h)help
          exit 0
          ;;
        ?)
          echo "unkonw argument"
          exit 1
          ;;
   esac
done
#echo "- $product">$product_file
#echo "- \"{module}_{product}_$group\"">$group_file 
if ! test ${special_job};then special_job="";fi
for sub in `cat $module|grep "^\-.*"|cut -d " " -f2|sed s/:.*//g`;do 
#    jobs=`echo ${jobs} "${sub}_${product}${special_job}"`
    jobs=`echo ${jobs} "CCI_${sub}${special_job}"`
done

if [ ! -z "${special_subsystem+x}" ];then
  jobs=""
  defualt_types=(_TRIGGER _FLOW _CLOUD _IL  _BCN_FT _CLOUD_FT _CLOUD_IMAGE_PATCH_UPLOAD _GIT)
  echo "subsystem is specfic"
  for j_type in ${defualt_types[@]};do
    jobs="${jobs} CCI_${special_subsystem}${j_type}"
  done
fi

echo "these jobs wil be created: ${jobs}"

#refresh jenkisn jobs
if $Test;then
   echo "$jjb  --conf $jjb_configure_file  test -x config . ${jobs} -o output/"
   $jjb  --conf $jjb_configure_file  test -x config . ${jobs}  -o output/
else
   $jjb  --flush-cache --conf ${jjb_configure_file} update -x config -x .git . ${jobs}
fi

