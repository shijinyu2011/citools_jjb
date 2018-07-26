#!/bin/bash
# Stack launch related shell
if test -d cciscript;then 
   git --git-dir=cciscript/.git --work-tree=cciscript pull
else   
   git clone hzscm@hzling48.china.nsn-net.net:/linux_gerrit/gerrit/gitrepos/citools/cciscript.git
fi
DELIVERY_NAME=${DELIVERY_NAME//\//\_}
if test ! $heat_template;then 
    rm -fr rcp_ci_trigger
    svn export https://svne1.access.nsn.com/isource/svnroot/IPA_CI_triggers/RCP_CI_trigger/rcp_ci_trigger
    heat_template=`cat rcp_ci_trigger|grep "heat_template="|cut -d"=" -f2` 
fi
source cciscript/$ci_openrc
source cciscript/mkenv.sh
./cciscript/opt_template.sh $configurefile $publicExtnet $ZONE

if $LAUNCH;then
   echo "check if the instance exist"
   heat stack-delete $instance_name
   while [ "`heat stack-list|grep $instance_name`" ];do
       sleep 5
       retry=`heat stack-list|grep $instance_name|grep "DELETE_FAILED"`
       if [ "$retry" ];then
          heat stack-delete $instance_name
       fi
   done     
   echo "`date`:launch test instance" 
   echo "******************************************************************************"
   echo  "python $heat_operator stack-create $configurefile ${DELIVERY_NAME} $instance_name" 
   python $heat_operator stack-create $configurefile ${DELIVERY_NAME} $instance_name   
   if [ $? -ne 0 ];then
      exit 1
   fi
   echo "`date`:*************bound float ip************"
   INSTANCE_NAME_OR_ID=`nova list|grep UI-0|cut -d "|" -f2`
   INSTANCE=`nova floating-ip-list|grep "publicExtnet"|cut -d"|" -f3|sed "s/ //g"`
   nova floating-ip-associate $INSTANCE_NAME_OR_ID $INSTANCE
else
   echo "LAUNCH is $$LAUNCH,skip running launch instance"
fi


if $RUN_CASE;then
   echo "`date`:update test cases"
   echo "******************************************************************************" 
   
   if test ! -d $work_tree_RCPCI;then
       git clone  ssh://hzci@hzgitv01.china.nsn-net.net:29418/scm_rcp/SS_RCPCI $work_tree_RCPCI
       echo "* -text" > $git_dir_RCPCI/info/attributes 
   fi
 
   git --git-dir=${git_dir_RCPCI} --work-tree=${work_tree_RCPCI} fetch origin $testbranchname
   git --git-dir=${git_dir_RCPCI} --work-tree=${work_tree_RCPCI} checkout remotes/origin/$testbranchname
  echo "`date`:Run robot cases"
  echo "******************************************************************************" 

  INCLUDE_TAGS_OPTION=""
  if [ $INCLUDE_TAGS ]; then
     INCLUDE_TAGS_OPTION="-i $INCLUDE_TAGS"
  fi
  EXCLUDE_TAGS_OPTION=""
  if [ $EXCLUDE_TAGS ]; then
     EXCLUDE_TAGS_OPTION="-e $EXCLUDE_TAGS"
  fi
  
  TAG="$INCLUDE_TAGS_OPTION $EXCLUDE_TAGS_OPTION"
  LOGPATH="-d ${log_folder}"
  export PYTHONPATH=${work_tree_RCPCI}/libraries/rcplib

 echo "check ru status,please wait..."
 echo "******************************************************************************"
  sleep 60
  ./cciscript/sshlogin.sh $INSTANCE root rootme
   echo "wait ru to start up..."
   check=true
   while $check;do 
     status=`ssh root@$INSTANCE "/opt/nsn/bin/fsclish -c 'show has state managed-object /*/*'"`
     echo "$status"
     check=false
     while read line;do 
        echo "$status"|grep -q "$line"
        if [ `echo $?` = 1 ];then 
             check=true;             
        fi
     done < cciscript/checklist.txt
     sleep 50
  done
  result=0
  for sub in  `echo $TESTCASE`;do
       if test -d $CASEPATH/$sub;then
           for case in `cd $CASEPATH/$sub;find * | grep -v __init__\.html|grep "\.\(x\?html\?\)\|\(tsv\)\|\(txt\)\|\(rst\)\|\(rest\)"`;do
                sub_case_base_name=`echo ${sub}_$case |tr "\/" "_"|sed "s/\..*//g"`
                OUTPUT="-o output_${sub_case_base_name}.xml"
                REPORT="-r report_${sub_case_base_name}.html"
                LOG="-l log_${sub_case_base_name}.html"
                CASENAME="$CASEPATH/${sub}/$case"
                echo "pybot --nostatusrc -L TRACE -v WIFI_CONTROLLER_IP:$INSTANCE $TAG $OUTPUT  $REPORT $LOGPATH $LOG $CASENAME"
                pybot --nostatusrc -L TRACE -v WIFI_CONTROLLER_IP:$INSTANCE $TAG $OUTPUT  $REPORT $LOGPATH $LOG  $CASENAME
            done
        else 
           sub_case_base_name=`echo $sub|tr "\/" "_"|sed "s/\..*//g"`
           OUTPUT="-o output_${sub_case_base_name}.xml"
           REPORT="-r report_${sub_case_base_name}.html"
           LOG="-l log_${sub_case_base_name}.html"
           CASENAME="$CASEPATH/$sub"
           echo "pybot --nostatusrc -L TRACE -v WIFI_CONTROLLER_IP:$INSTANCE $TAG $OUTPUT  $REPORT $LOGPATH $LOG $CASENAME"
           pybot --nostatusrc -L TRACE -v WIFI_CONTROLLER_IP:$INSTANCE $TAG $OUTPUT  $REPORT $LOGPATH $LOG $CASENAME
        fi
   done
   error_file_name=`grep -w  "fail.:[^0][0-9]*,.label.:.All Tests" -R  ${log_folder}/*|cut -d: -f 1 | sort | uniq |grep "html"`
   cp -rf  ${error_file_name}  ${errlog_path}/
   if [ "`echo ${error_file_name}`" != "" ];then result=1;fi
else 
   echo "RUN_CASE is false,skip running test case"
fi

scp root@$INSTANCE:/var/log/local/syslog  ./logs/
scp root@$INSTANCE:/var/log/local/debug   ./logs/
scp root@$INSTANCE:/var/log/fsaudit/auth.log  ./logs/
scp root@$INSTANCE:/var/log/fsaudit/alarms  ./logs/
   
if $RELEASE;then
   echo "`date`: release test instance"
   echo "******************************************************************************"
   heat stack-delete $instance_name
   while [ "`heat stack-list|grep $instance_name`" ];do
       sleep 5
       retry=`heat stack-list|grep $instance_name|grep "DELETE_FAILED"`
       if [ "$retry" ];then
          heat stack-delete $instance_name
       fi
   done  
else
   echo "Skip stack release"
fi

exit $result