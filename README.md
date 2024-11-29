# ./knoxcli command options
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
## [cluster] command

[cluster] command operates on Kubernetes and Virtual Machines based clusters.

### [cluster alerts] command

Options supported:
* --clusterjq [jq-spec]: jq filter to be used on cluster list output (default: '.[]')
* --alertjq [jq-spec]: jq filter to be used on cluster list output (default: '.')
* --stime [datetime]: start time in epoch format (default: '1732724310', 2 days ago)
* --etime [datetime]: end time in epoch format (default: '1732897110', now)
* --type [alert-type]: alert-type (default: "kubearmor")
* --filters [filter-spec]: Alert filters to be passed to API (default: '')

Examples:
1. knoxcli cluster alerts --alertjq '.response[] | select(.Resource // "unknown" | test("ziggy"))' <br>
	... list all the alerts containing 'ziggy' in the Resource filter
2. knoxcli cluster alerts --filters '{"field":"HostName","value":"store54055","op":"match"}' --alertjq '.response[] | "hostname=\(.HostName),resource=\(.Resource//""),UID=\(.UID),operation=\(.Operation)"' <br>
	... get all alerts for HostName="store54055" and print the response in following csv format hostname,resource,UID,operation

> Difference between --alertjq and --filters? <br>
> --filters are passed directly to the AccuKnox API. --alertjq operates on the output of the AccuKnox API response. It is recommended to use --filters as far as possible. However, you can use regex/jq based matching criteria with --alertjq.

### [cluster list] command
* --spec | -s: [requires value] search filter for cluster names (regex based)
* --nodes | -n: lists nodes from the clusters
* --clusterjq: jq filter to be used on cluster list output (default: '.[]')
* --nodejq: jq filter to be used on node list output (default: '.result[].NodeName')

Examples:

1. knoxcli cluster list --clusterjq '.[] | select(.ClusterName|test("idt."))' --nodes <br>
	... list all the clusters with idt substring in its names and list all the nodes in those clusters
2. knoxcli cluster list --clusterjq '.[] | select((.type == "vm") and (.Status == "Inactive")) | "id=\(.ID),name=\(.ClusterName),status=\(.Status)"' <br>
	... list all the Inactive VM clusters and print their ID,name,status

### [cluster policy] command
* --operation [list | dump]: Dump the policies in --dumpdir folder or list the policies
* --dumpdir | -d: Policy dump directory
* --clusterjq: jq filter to be used on cluster list output (default: '.[]')
* --policyjq: jq filter to be used on policy list output (default: '.')

Examples:

1. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.name|test("crypto"))' <br>
	... get all the policies have 'crypto' in their name for all the clusters having 'gke' in their name

2. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.namespace_name // "notpresent"|test("agents"))' <br>
	... get all the policies in namespace agents ... if no namespace is present then "notpresent" is substituted.
## [image] command
[image] commands operates on container images and corresponding findings.

image list [options]
      --filter | -f: image list filters
      --label  | -l: image assets with label
image scan [options]
      --spec | -s: Images to be scanned (regex can be specified)
