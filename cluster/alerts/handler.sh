clusterjq='.[] | select(.ClusterName|test("idt")'
alertjq='.'
stimestr="2 days ago"
stime=$(date -d "$stimestr" +%s)
etime=$(date +%s)
alerttype="kubearmor"
filters=""

cluster_alerts_query()
{
	for((pgid=1;;pgid++)); do
		data_raw="{\"Namespace\":[],\"FromTime\":$stime,\"ToTime\":$etime,\"PageId\":$pgid,\"PageSize\":50,\"Filters\":[$filters],\"ClusterID\":[$cidlist],\"View\":\"List\",\"Type\":\"$alerttype\",\"WorkloadType\":[],\"WorkloadName\":[],\"WorkspaceID\":$TENANT_ID}"
		ak_api "$CWPP_URL/monitors/v1/alerts/events?orderby=desc"
		acnt=$(echo $json_string | jq '.response | length')
		[[ $acnt -le 0 ]] && break
		echo $json_string | jq "$alertjq"
	done
}

ca_generic_handler()
{
	case "$1" in
		type ) alerttype="$2" ;;
		clusterjq ) clusterjq="$2" ;;
		alertjq ) alertjq="$2" ;;
		filters ) filters="$2" ;;
		stime ) stime="$2" ;;
		etime ) etime="$2" ;;
		* ) echo "UNKNOWN argopt" ;;
	esac
}

ca_help()
{
	cat <<EOH
### [cluster alerts] options
Show alerts in the context of clusters. These alerts could be from KubeArmor, Network policies, Admission controllers or anything else as reported in "Monitors & Alerts" option in AccuKnox Control Plane.

EOH
	arghelp
	cat <<EOH
Examples:

	1. knoxcli cluster alerts --alertjq '.response[] | select(.Resource // "unknown" | test("ziggy"))'
		... list all the alerts containing 'ziggy' in the Resource filter
	2. knoxcli cluster alerts --filters '{"field":"HostName","value":"store54055","op":"match"}' --alertjq '.response[] | "hostname=\(.HostName),resource=\(.Resource//""),UID=\(.UID),operation=\(.Operation)"'
		... get all alerts for HostName="store54055" and print the response in following csv format hostname,resource,UID,operation

> **Difference between --alertjq and --filters?** <br>
> --filters are passed directly to the AccuKnox API. --alertjq operates on the output of the AccuKnox API response. It is recommended to use --filters as far as possible. However, you can use regex/jq based matching criteria with --alertjq.

EOH
}

cluster_alerts_args()
{
	arginit
	argopt 	--lopt "type" --needval --handler "ca_generic_handler" \
			--desc "set alert type (default: $alerttype)"

	argopt 	--lopt "clusterjq" --needval --handler "ca_generic_handler" \
			--desc "jq filter to be used on cluster list output (default: '$clusterjq')"

	argopt 	--lopt "alertjq" --needval --handler "ca_generic_handler" \
			--desc "jq filter to be used on cluster list output (default: '$alertjq')"

	argopt 	--sopt "f" --needval --lopt "filters" --handler "ca_generic_handler" \
			--desc "Alert filters to be passed to API (default: '$filters')"

	argopt 	--sopt "s" --needval --lopt "stime" --handler "ca_generic_handler" \
			--desc "start time in epoch format (default: $stimestr)"

	argopt 	--sopt "e" --needval --lopt "etime" --handler "ca_generic_handler" \
			--desc "end time in epoch format (default: now)"

	argopt 	--sopt "h" --lopt "help" --handler "ca_help" \
			--desc "help with the options"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1
	[[ $etime -lt $stime ]] && echo "etime should be greater than stime" && return 2
	return 0
}

cluster_alerts_cmd()
{
	cluster_alerts_args "$@"
	[[ $? -ne 0 ]] && return 1
	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	final_json=$(echo $json_string | jq -r "$clusterjq")
	cidlist=""
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		[[ "$cidlist" != "" ]] && cidlist="$cidlist,"
		cidlist="$cidlist\"$cid\""
	done < <(echo $final_json | jq -r '. | "\(.ID) \(.ClusterName)"')
	cluster_alerts_query
}

