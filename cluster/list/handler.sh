clusterjq='.[] | "id=\(.ID),name=\(.ClusterName),status=\(.Status)"'
nodejq='.result[].NodeName'
show_nodes=0

cluster_list_get_node_list()
{
	echo "List of nodes in cluster [$cname]:"
	data_raw="{\"workspace_id\":$TENANT_ID,\"cluster_id\":[$cid],\"from_time\":[],\"to_time\":[]}"
	ak_api "$CWPP_URL/cm/api/v1/cluster-management/nodes-in-cluster"
	echo $json_string | jq -r "$nodejq"
}

cl_generic_handler()
{
	case "$1" in
		"nodejq" ) nodejq="$2" ;;
		"clusterjq" ) clusterjq="$2" ;;
		"nodes" ) show_nodes=1 ;;
		*) echo "UNHANDLER argopt";;
	esac
}

cl_help()
{
	cat <<EOH
### [cluster list] options
List the cluster and corresponding nodes or any other entities (namespaces, workloads) as part of the cluster.

EOH
	arghelp
	cat <<EOH

Examples:

	1. knoxcli cluster list --clusterjq '.[] | select(.ClusterName|test("idt."))' --nodes
		... list all the clusters with idt substring in its names and list all the nodes in those clusters
	2. knoxcli cluster list --clusterjq '.[] | select((.type == "vm") and (.Status == "Inactive")) | "id=\(.ID),name=\(.ClusterName),status=\(.Status)"'
		... list all the Inactive VM clusters and print their ID,name,status

EOH
}

cluster_list_cmd()
{
	arginit
	argopt 	--lopt "clusterjq" --needval --handler "cl_generic_handler" \
			--desc "jq filter to be used on cluster list output (default: '$clusterjq')"

	argopt 	--lopt "nodejq" --needval --handler "cl_generic_handler" \
			--desc "jq filter to be used on node list output (default: '$nodejq')"

	argopt	--sopt "n" --lopt "nodes" --handler "cl_generic_handler" \
			--desc "lists nodes from the clusters"

	argopt	--sopt "h" --lopt "help" --handler "cl_help" \
			--desc "help for cluster list"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1

	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	final_json=$(echo $json_string | jq -r "$clusterjq")
	echo $final_json | jq .
	[[ $show_nodes -eq 0 ]] && return
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		cluster_list_get_node_list
	done < <(echo $final_json | jq -r '. | "\(.ID) \(.ClusterName)"')
}

