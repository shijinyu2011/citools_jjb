- bool:
   name: LAUNCH
   default: true
   description: "Launch stack"
- bool:
   name: RUN_CASE
   default: true
   description: "Run Cases"
- bool:
   name: RELEASE
   default: true
   description: "Stop stack"
- string:
   name: INCLUDE_TAGS
   default: type-SWBT
   description:  |
     "Select test cases to run by tag. Tag is case and space insensitive and it is possible to use patterns with `*` and `?` as wildcards. 
      Tags and patterns can also be combined together with `AND`, `OR`, and `NOT` operators.
      Examples: fooANDbar*"
- string:
   name: EXCLUDE_TAGS
   default:
   description: |
     "Select test cases not to run by tag. These tests are not run even if included with INCLUDE_TAGS. 
      Tags are matched using the rules explained with INCLUDE_TAGS."
- string:
   name: DELIVERY_NAME
   default: 
   description: "Image name to deliver"
- string:
   name: INSTANCE
   default: 10.70.78.70
   description: "Instance IP"
- string:
   name: heat_template
   description: "example: http://rcp.dynamic.nsn-net.net/rcp/release/RCP_15.19.0/RCP_15.19.0.yaml"
- string:
   name: instance_name
   default: SCM_CI_TEST
- string:
   name: TESTCASE
   default: testcases/rcp/System_level/RCP_SYS_002_Lock_Unlock_Cluster.txt

   
   
   