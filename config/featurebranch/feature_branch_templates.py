feature_template = '''
- job:
    name:
    project-type: flow
    dsl:
    triggers:
'''


feature_parallel_jobs_template = '''
{ build("%(modules)s_COMPILE",GERRIT_SCHEME:params["GERRIT_SCHEME"],GERRIT_HOST:params["GERRIT_HOST"],GERRIT_PORT:params["GERRIT_PORT"],GERRIT_PROJECT:params["GERRIT_PROJECT"],GERRIT_BRANCH:params["GERRIT_BRANCH"],GERRIT_REFSPEC:params["GERRIT_REFSPEC"],parent_buildnum:build.number) },
{ build("%(modules)s_STATIC_ANALYSIS",GERRIT_SCHEME:params["GERRIT_SCHEME"],GERRIT_HOST:params["GERRIT_HOST"],GERRIT_PORT:params["GERRIT_PORT"],GERRIT_PROJECT:params["GERRIT_PROJECT"],GERRIT_BRANCH:params["GERRIT_BRANCH"],GERRIT_REFSPEC:params["GERRIT_REFSPEC"]) },
{ build("%(modules)s_UT",GERRIT_SCHEME:params["GERRIT_SCHEME"],GERRIT_HOST:params["GERRIT_HOST"],GERRIT_PORT:params["GERRIT_PORT"],GERRIT_PROJECT:params["GERRIT_PROJECT"],GERRIT_BRANCH:params["GERRIT_BRANCH"],GERRIT_REFSPEC:params["GERRIT_REFSPEC"]) },
'''

feature_dsl_template = '''
parallel (
    %(module_subjobs)s
)
build("%(feature)s_image_patch_upload",target_image_name:params["GERRIT_REFSPEC"],parent_buildnum:build.number)
build("%(feature)s_FT",DELIVERY_NAME:params["GERRIT_REFSPEC"])
'''

feature_trigger_template = '''
- gerrit:
    trigger-on:
       - patchset-created-event
    projects:
'''
