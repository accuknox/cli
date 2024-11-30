clusterjq='.[]'
policyjq='.'
polout="policydump"
operation="list"

cluster_policy_dump_policy_file()
{
	ak_api "$CWPP_URL/policymanagement/v2/policy/$1"
	echo "$json_string" | jq -r .yaml > $polpath
	[[ $? -ne 0 ]] && echo "could not get policy with ID=[$1]" && return
}

cluster_policy_get_policy_list()
{
	polperpage=10
	for((pgprev=0;;pgprev+=$polperpage)); do
		pgnext=$(($pgprev + $polperpage))
		echo "fetching policies $pgprev to $pgnext ..."
		data_raw="{\"workspace_id\":$TENANT_ID,\"workload\":\"k8s\",\"page_previous\":$pgprev,\"page_next\":$pgnext,\"filter\":{\"cluster_id\":[$1],\"namespace_id\":[],\"workload_id\":[],\"kind\":[],\"node_id\":[],\"pod_id\":[],\"type\":[],\"status\":[],\"tags\":[],\"name\":{\"regex\":[]},\"tldr\":{\"regex\":[]}}}"
		ak_api "$CWPP_URL/policymanagement/v2/list-policy"
		pcnt=$(echo "$json_string" | jq '.list_of_policies | length')
		[[ $pcnt -eq 0 ]] && echo "finished" && break
		final_json=$(echo "$json_string" | jq -r "$policyjq")
		[[ "$final_json" == "" ]] && continue
		while read pline; do
			arr=($pline)
			if [ "$operation" == "dump" ]; then
				poldir=$cpath/${arr[2]}
				mkdir -p $poldir 2>/dev/null
				polpath=$poldir/${arr[1]}.yaml
				echo $polpath
			else
				polpath=/dev/stdout
			fi
			cluster_policy_dump_policy_file ${arr[0]}
		done < <(echo $final_json | jq -r '. | "\(.policy_id) \(.name) \(.namespace_name)"')
	done
}

cp_help()
{
	cat <<EOH
### [cluster policy] options
Enlist the cluster policies. These include all policies, including, KubeArmor, Network, Admission Controller policies.

EOH
	arghelp
	cat <<EOH
Examples:

	1. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.name|test("crypto"))'
		... get all the policies have 'crypto' in their name for all the clusters having 'gke' in their name
	2. knoxcli cluster policy --clusterjq '.[] | select(.ClusterName|test("gke"))' --policyjq '.list_of_policies[] | select(.namespace_name // "notpresent"|test("agents"))'
		... get all the policies in namespace agents ... if no namespace is present then "notpresent" is substituted.

EOH
}

cp_generic_handler()
{
	case "$1" in
		operation)    operation="$2";                shift 2;;
		clusterjq)    clusterjq="$2";                shift 2;;
		policyjq)     policyjq="$2";                 shift 2;;
		dumpdir) polout="$2"; operation="dump"; shift 2;;
		help )  cp_help; return 2;;
		* ) echo "UNKNOWN OPT" ;;
	esac
}


cluster_policy_cmd()
{
	arginit
	argopt  --lopt "operation" --needval --handler "cp_generic_handler" \
			--desc "[list|dump] Dump the policies in folder or list the policies. default:$operation"

	argopt  --lopt "clusterjq" --needval --handler "cp_generic_handler" \
			--desc "jq filter to be used on cluster list output (default: '$clusterjq')"

	argopt  --lopt "policyjq" --needval --handler "cp_generic_handler" \
			--desc "jq filter to be used on policy list output (default: '$policyjq')"

	argopt  --sopt "d" --lopt "dumpdir" --needval --handler "cp_generic_handler" \
			--desc "Policy dump directory"

	argopt 	--sopt "h" --lopt "help" --handler "cp_help" \
			--desc "help with the options"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1
	[[ "$operation" != "list" ]] && [[ "$operation" != "dump" ]] && \
		echo "invalid operation [$operation]!" && return 1

	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	filter_json=$(echo $json_string | jq -r "$clusterjq")
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		if [ "$operation" == "dump" ]; then
			cpath=$polout/$cname
			mkdir $cpath 2>/dev/null
		fi
		echo "fetching policies for cluster [$cname] ..."
		cluster_policy_get_policy_list $cid
	done < <(echo "$filter_json" | jq -r '. | "\(.ID) \(.ClusterName)"')
}

