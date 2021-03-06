#!/bin/bash
# Stack launch related shell
if test -d cciscript;then 
   git --git-dir=cciscript/.git --work-tree=`pwd`/cciscript pull
else   
   git clone hzscm@hzling48.china.nsn-net.net:/linux_gerrit/gerrit/gitrepos/citools/cciscript.git
fi
DELIVERY_NAME=${DELIVERY_NAME//\//\_}
trigger_url="https://svne1.access.nsn.com/isource/svnroot/IPA_CI_triggers/RCP_release_trigger/rcp_release_trigger"
trigger_file="rcp_release_trigger"

if test ! $heat_template;then 
    rm -fr $trigger_file
    svn export $trigger_url $trigger_file
    heat_template=`cat $trigger_file|grep "heat_template="|cut -d"=" -f2` 
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
   nova floating-ip-associate $INSTANCE_NAME_OR_ID $INSTANCE || nova floating-ip-associate $INSTANCE_NAME_OR_ID $INSTANCE
else
   echo "LAUNCH is $$LAUNCH,skip running launch instance"
fi

if test -n "${INSTANCE}";then sed -i "/.*${INSTANCE}.*/d"  ~/.ssh/known_hosts;fi

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
  if test -n "$INCLUDE_TAGS";then 
    for i in `echo "$EXCLUDE_TAGS"`;do 
         INCLUDE_TAGS_OPTION="-e $i $INCLUDE_TAGS_OPTION";
    done;
  fi
  
  EXCLUDE_TAGS_OPTION=""
  if test -n "$EXCLUDE_TAGS";then 
    for i in `echo "$EXCLUDE_TAGS"`;do 
         EXCLUDE_TAGS_OPTION="-e $i $EXCLUDE_TAGS_OPTION";
    done;
  fi
  
  
  HOST="-v HOSTNAME:$INSTANCE -v USERNAME:_nokadmin -v PASSWORD:Nokia123"
  TAG="$INCLUDE_TAGS_OPTION $EXCLUDE_TAGS_OPTION"
  LOGPATH="-d ${log_folder}"
  export PYTHONPATH=${work_tree_RCPCI}/libraries/rcplib

 echo "sleep 240s first, check ru status,please wait..."
 sleep 240
 echo "******************************************************************************"
   check=true
   while $check;do 
     ./cciscript/checkstatus.sh $INSTANCE _nokadmin Nokia123>temp
     status=`cat temp`
     echo "$status"
     cat temp|cut -d " " -f1|grep "/">checklist
     check=false
     while read line;do 
        echo "$status"|grep -e "${line}.*UNLOCKED.*ENABLED.*ACTIVE.*ACTIVE.*-.*-"
        if [ `echo $?` = 1 ];then 
             check=true;             
        fi
     done < checklist
     if $check;then sleep 30;fi
   done
  result=0
  if  test -z $TESTCASE;then TESTCASE=`cat cciscript/rcp_cci_case.config|grep "${JOB_NAME/_FT*/}:"|cut -d":" -f2`;fi 
  
  for sub in  `echo $TESTCASE`;do
       if test -d $CASEPATH/$sub;then
           for case in `cd $CASEPATH/$sub;find * | grep -v __init__\.html|grep "\.\(x\?html\?\)\|\(tsv\)\|\(txt\)\|\(rst\)\|\(rest\)"`;do
                sub_case_base_name=`echo ${sub}_$case |tr "\/" "_"|sed "s/\..*//g"`
                OUTPUT="-o output_${sub_case_base_name}.xml"
                REPORT="-r report_${sub_case_base_name}.html"
                LOG="-l log_${sub_case_base_name}.html"
                CASENAME="$CASEPATH/${sub}/$case"
                echo "pybot --nostatusrc -L TRACE $HOST $TAG $OUTPUT  $REPORT $LOGPATH $LOG $CASENAME"
                pybot --nostatusrc -L TRACE $HOST $TAG $OUTPUT  $REPORT $LOGPATH $LOG  $CASENAME
            done
        else 
           sub_case_base_name=`echo $sub|tr "\/" "_"|sed "s/\..*//g"`
           OUTPUT="-o output_${sub_case_base_name}.xml"
           REPORT="-r report_${sub_case_base_name}.html"
           LOG="-l log_${sub_case_base_name}.html"
           CASENAME="$CASEPATH/$sub"
           echo "pybot --nostatusrc -L TRACE $HOST $TAG $OUTPUT  $REPORT $LOGPATH $LOG $CASENAME"
           pybot --nostatusrc -L TRACE $HOST $TAG $OUTPUT  $REPORT $LOGPATH $LOG $CASENAME
        fi
   done
   error_file_name=`grep -w  "fail.:[^0][0-9]*,.label.:.All Tests" -R  ${log_folder}/*|cut -d: -f 1 | sort | uniq |grep "html"`
   cp -rf  ${error_file_name}  ${errlog_path}/
   if [ "`echo ${error_file_name}`" != "" ];then result=1;fi
else 
   echo "RUN_CASE is false,skip running test case"
fi


logfiles="/var/log/local/syslog /var/log/local/debug /var/log/fsaudit/auth.log /var/log/fsaudit/alarms"
for i in `echo $logfiles`;do 
   ./cciscript/collect_syslog.sh $INSTANCE _rcpadmin RCP_owner $i;
done  
   
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