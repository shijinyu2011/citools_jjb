#!/bin/bash -e
BRANCH=${{GERRIT_BRANCH}}
# svnserver="https://svne1.access.nsn.com"
# auth="--username hzci --password b2a6eefb --non-interactive --trust-server-cert "
# svn cat $auth "${{svnserver}}/isource/svnroot/scm_il/branches/${{BRANCH}}/commonil_gitrepo.lst" > gitrepo.list
git archive --format=tar --remote=git@gitlabe1.ext.net.nokia.com:IL_SCM/common_il.git master commonil_gitrepo.lst | tar -xO -f - > gitrepo.list
if [ "${{GERRIT_BRANCH}}" = "cloudVT" ];then
   type="cloud"
else
   type=il
   cat gitrepo.list |grep "${{GERRIT_PROJECT}} " && type=common
fi
echo $type > property