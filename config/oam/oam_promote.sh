SVN_REV=`cat svn_revision.txt`

TRUNK="${MODULE_SVN_URL}"
PTRUNK="${BRANCH}"

echo "***************************************************************"
echo "*** CHECK IF PROMOTION IS NEEDED                            ***"
echo "*** trunk revision greater than promoted revision    ***"

echo "*** Check current promoted revision       ***"
current_promo_rev=`svn info ${PTRUNK} | sed -n "s/^Last Changed Rev: \(.*\)$/\1/p"`
current_cp_trunk_rev=`svn log ${PTRUNK}@${current_promo_rev} -l 1 | grep Automatic| sed -n 's/.*SVN revision \(.*\)$/\1/p'`
echo "CURRENT promoted revision: ${current_promo_rev} copy from ${current_cp_trunk_rev}"
if [ -n "${current_cp_trunk_rev}" ] && [ ${current_promo_rev} -gt ${current_cp_trunk_rev} ]; then current_promo_rev=${current_cp_trunk_rev};fi;


echo "*** compare trunk and promoted revisions  ***"
if [ ${SVN_REV} -le ${current_promo_rev} ]
then
  echo "**** trunk revision is NOT greater than promoted revision. ****"
  echo "**** Copying is not done! **** "
  exit -1
else
  echo "******************************"
  echo "*** COPY FROM TRUNK        ***"
  svn export --force https://svne1.access.nsn.com/isource/svnroot/citools/scripts/trunk/ciscript/OAM_CI/ftsvnpromotion.pl
  #echo "*** COPY DISABLED UNTIL ARICENT CI IS BRANCHED FROM TRUNK ***"
  perl ftsvnpromotion.pl "master" "${TRUNK}" "${PTRUNK}" "${SVN_REV}" "Automatic code promotion for wcdma16_promoted, SVN revision ${SVN_REV}"
fi