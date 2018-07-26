'''
This script used to create view by python module <jenkinsapi> based on yaml config
0) wget https://bootstrap.pypa.io/get-pip.py
1) pip install jenkinsapi
2) doc: https://jenkinsapi.readthedocs.org/en/latest/

Other jenkins Webapi:
    1) http://jenkins-webapi.readthedocs.org/en/latest/

'''
import jenkinsapi
from jenkinsapi.jenkins import Jenkins
from jenkinsapi.views import Views
import re
import yaml

yaml_template = '''
- jenkins_basic:
    baseurl: http://10.159.28.179:8080/jenkins/
    username: j69chen
    password: 1f31f432e08457337f6aba6a6ae92b76

- view_structure:
    - name: featureBranch
      type: NESTED
      config:
      subviews:
        - name: feature01
          type: SECTIONED
          config: section_feature_config.xml
        - name: feature02
          type: SECTIONED
          config: section_feature_config.xml
    - name: listview
      type: LIST
      config:
'''

class JenkinsAction(object):
    VIEW_TYPES = {
        'NESTED': Views.NESTED_VIEW,
        'LIST': Views.LIST_VIEW,
        'SECTIONED': 'hudson.plugins.sectioned_view.SectionedView',
        'MY': Views.MY_VIEW,
        'PIPELINE': Views.PIPELINE_VIEW, 
        'DASHBOARD': Views.DASHBOARD_VIEW,     
    }

    def __init__(self):
        self.yaml_config = yaml.load(yaml_template)
        self.client = self.auth()
    
    def auth(self):
        config = filter(lambda x: x.has_key('jenkins_basic'), self.yaml_config)[0]
        return Jenkins(**config)
    
    def create_views(self):
        view_structure = filter(lambda x: x.has_key('view_structure'), yaml_config)[0]
        config_views = view_structure['view_structure']
        self._create_view(self.client)
    
    def _create_view(self, parent, views):
        for v in views:
            child = parent.views.create(v['name'], VIEW_TYPES.get(v['type']))
            if v.get('config'):
                with open(v.get('config'), 'rb') as f:
                    child.update_config(f.read().replace('feature01', v['name']))
            if v.get('subviews'):
                self._create_view(child, v.get('subviews'))

    def delete_views(self, pattern):
        view_names = self.client.views.keys()
        for v in views_names:
            if re.search(pattern, v):
                self.client.views[v].delete()

    def delete_jobs(self, pattern='feature\d+-.*|SS_IL.*'):
        for j in self.client.jobs.iterkeys():
            if re.search('(?i)^(%s)'%pattern, j):
                client.delete_job(j)
    
    def disable_job(self, job):
        if self.client.has_job(job):
            instance = self.client.get_job(job)
            instance.disable()

def main():
    o = JenkinsAction()
    o.create_views()

if __name__ == '__main__':
    main()

