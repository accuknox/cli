```
██╗  ██╗███╗   ██╗ ██████╗ ██╗  ██╗ ██████╗██╗     ██╗
██║ ██╔╝████╗  ██║██╔═══██╗╚██╗██╔╝██╔════╝██║     ██║
█████╔╝ ██╔██╗ ██║██║   ██║ ╚███╔╝ ██║     ██║     ██║
██╔═██╗ ██║╚██╗██║██║   ██║ ██╔██╗ ██║     ██║     ██║
██║  ██╗██║ ╚████║╚██████╔╝██╔╝ ██╗╚██████╗███████╗██║
╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝
```
# knoxcli command options
```
./knoxcli
	cluster
	cluster alerts
	cluster list
	cluster policy
	image
	image list
	image scan
	version
	help
```
check further [cluster] options ...
### [cluster alerts] options
Show alerts in the context of clusters. These alerts could be from KubeArmor, Network policies, Admission controllers or anything else as reported in "Monitors & Alerts" option in AccuKnox Control Plane.

Supported options:

	--type [value] => set alert type (default: kubearmor). 
	--clusterjq [value] => jq filter to be used on cluster list output (default: '.[]'). 
	--alertjq [value] => jq filter to be used on cluster list output (default: '.'). 
	-f | --filters [value] => Alert filters to be passed to API (default: ''). 
	-s | --stime [value] => start time in epoch format (default: ). 
	-e | --etime [value] => end time in epoch format (default: now). 
	-h | --help => help with the options. 
Examples:

	1. knoxcli cluster alerts --alertjq '.response[] | select(.Resource // "unknown" | test("ziggy"))'
		... list all the alerts containing 'ziggy' in the Resource filter
	2. knoxcli cluster alerts --filters '{"field":"HostName","value":"store54055","op":"match"}' --alertjq '.response[] | "hostname=\(.HostName),resource=\(.Resource//""),UID=\(.UID),operation=\(.Operation)"'
		... get all alerts for HostName="store54055" and print the response in following csv format hostname,resource,UID,operation

> **Difference between --alertjq and --filters?** <br>
> --filters are passed directly to the AccuKnox API. --alertjq operates on the output of the AccuKnox API response. It is recommended to use --filters as far as possible. However, you can use regex/jq based matching criteria with --alertjq.

### [cluster list] options
List the cluster and corresponding nodes or any other entities (namespaces, workloads) as part of the cluster.

Supported options:

	--clusterjq [value] => jq filter to be used on cluster list output (default: '.[]'). 
	--nodejq [value] => jq filter to be used on node list output (default: '.result[].NodeName'). 
	-n | --nodes => lists nodes from the clusters. 
	-h | --help => help for cluster list. 

Examples:

	1. knoxcli cluster list --clusterjq '.[] | select(.ClusterName|test("idt."))' --nodes
		... list all the clusters with idt substring in its names and list all the nodes in those clusters
	2. knoxcli cluster list --clusterjq '.[] | select((.type == "vm") and (.Status == "Inactive")) | "id=\(.ID),name=\(.ClusterName),status=\(.Status)"'
		... list all the Inactive VM clusters and print their ID,name,status

### [cluster policy] options
Enlist the cluster policies. These include all policies, including, KubeArmor, Network, Admission Controller policies.

Supported options:

	--operation [value] => [list|dump] Dump the policies in folder or list the policies. default:list. 
	--clusterjq [value] => jq filter to be used on cluster list output (default: '.[]'). 
	--policyjq [value] => jq filter to be used on policy list output (default: '.'). 
	-d | --dumpdir [value] => Policy dump directory. 
	-h | --help => help with the options. 
Examples:

	1. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.name|test("crypto"))'
		... get all the policies have 'crypto' in their name for all the clusters having 'gke' in their name
	2. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.namespace_name // "notpresent"|test("agents"))'
		... get all the policies in namespace agents ... if no namespace is present then "notpresent" is substituted.

## [image] command
[image] commands operates on container images and corresponding findings.

### [image list] options
List the images.

Supported options:

	-f | --filter [value] => filter to be used with image list. 
	--imagejq [value] => jq based filter to use with image list. 
	-h | --help => help for cluster list. 

Examples:

	1. knoxcli image list
		... list all the images

image scan [options]
      --spec | -s: Images to be scanned (regex can be specified)
## Using docker

```bash
docker run -v $HOME/.accuknox.cfg:/root/.accuknox.cfg accuknox/knoxcli:main
```
