'''
This script uses pyYaml to generate new yaml based on template.
1) Documation: <http://pyyaml.org/wiki/PyYAMLDocumentation>
2) package: 
  pyYaml: <http://pyyaml.org/download/pyyaml/>
  libyaml(option): <http://pyyaml.org/download/libyaml/yaml-0.1.5.tar.gz>
  
The feature branch project config is like:

- job:
    name: test_job
    triggers:
      - gerrit:
           trigger-on:
              - patchset-created-event
           projects:
              - project-compare-type: "PLAIN"
                project-pattern: 'scm_il/subsystem'
                branches:
                   - branch-compare-type: 'PLAIN'
                     branch-pattern: 'feature_branch'

              - project-compare-type: "PLAIN"
                project-pattern: 'scm_rcp/subsystem'
                branches:
                   - branch-compare-type: 'PLAIN'
                     branch-pattern: 'feature_branch'
'''
import yaml
import os
from copy import deepcopy
from feature_branch_templates import feature_template, feature_parallel_jobs_template
from feature_branch_templates import feature_dsl_template, feature_trigger_template

class YamlConstructor(object):
    def _yaml_include(self, loader, node):
        # Get the path out of the yaml file
        file_name = os.path.join(os.path.dirname(loader.name), node.value)
        with open(file_name) as inputfile:
            return yaml.load(inputfile)
    
    def _yaml_include_raw(self, loader, node):
        # Get the path out of the yaml file
        file_name = os.path.join(os.path.dirname(loader.name), node.value)
        with open(file_name) as inputfile:
            return inputfile.read()
    
    def yaml_add_constructor(self):
        yaml.add_constructor("!include", self._yaml_include)
        yaml.add_constructor("!include-raw", self._yaml_include_raw)
    
class FeatureCI(object):
    def __init__(self, feature_config=None):
        self.features = feature_config
    
    def load_templates(self):
        feature_yaml = yaml.load(feature_template)[0]
        feature_trigger_yaml = yaml.load(feature_trigger_template)
        return feature_yaml, feature_trigger_yaml
    
    def load_feature_config(self):
        with file(self.features) as f:
            featuresYaml = yaml.load(f)
        return featuresYaml

    def dump_feature_jobs(self, output='feature-yaml-01.yaml'):
        feature_yamldata = []
        f_template, f_trig_template = self.load_templates()
        for f in self.load_feature_config():            
            job = deepcopy(f_template)
            trigger = deepcopy(f_trig_template)
            feature = f.keys()[0]
            modules = f.values()[0].get('subsystems')
            branch = f.values()[0].get('branch')
            modules_builders = []
            project_triggers = []
            for m in modules:
                m_name = m.keys()[0]
                scmurl = m.values()[0].get('scmurl')
                m_jobs =  feature_parallel_jobs_template% {'modules': '%s-%s'%(feature, m_name)}
                project_trigger = {'project-pattern': '%s/%s'%(scmurl, m_name), \
                           'branches': [{'branch-compare-type': 'PLAIN', 'branch-pattern': '%s'%branch}], \
                           'project-compare-type': 'PLAIN'}        
                modules_builders.append(m_jobs)
                project_triggers.append(project_trigger)
            modules_builders = ''.join(modules_builders)
            dsl_parameters = feature_dsl_template % {'module_subjobs':modules_builders, 'feature': feature}
            trigger[0]['gerrit']['projects'] = project_triggers
            job['job']['name'] = feature
            job['job']['dsl'] = dsl_parameters
            job['job']['triggers'] = trigger
            feature_yamldata.append(job)
        self.dump_yaml(feature_yamldata, output)

    def run(self):
        YamlConstructor().yaml_add_constructor()
        self.dump_feature_jobs()
        self.dump_module_jobs()
    
    def dump_module_jobs(self, modules_yaml_sample='feature_branch_cci.yaml', output='feature-yaml-02.yaml'):
        with open(modules_yaml_sample) as f:
            modules = yaml.load(f)
        
        project_cci = filter(lambda x: x.has_key('project') and x.get('project').get('name')=='feature_branch_module_cci', modules)[0]
        project_test = filter(lambda x: x.has_key('project') and x.get('project').get('name')=='feature_branch_testing', modules)[0]
        
        feature_list = []
        subsystem_list = []
        for features in self.load_feature_config():
            feature = features.keys()[0]
            feature_list.append(feature)
            subsystems = features.get(feature).get('subsystems')
            for ss in subsystems:
                ss = ss.keys()[0]
                subsystem_list.append({ss:{'feature':feature}})
        project_cci.get('project')['module'] = subsystem_list
        project_test.get('project')['feature'] = feature_list
        self.dump_yaml(modules, output)        
  
    def dump_yaml(self, data, output):
        with open(output, 'wb') as f:
            yaml.dump(data, f)
            print "Yaml file generated: ", output

def main():
    o = FeatureCI('feature_all.yaml.inc')
    o.run()

if __name__ == '__main__':
    main()
