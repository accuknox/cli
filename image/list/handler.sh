filter=""
imagejq="."

il_help()
{
	cat <<EOH
### [image list] options
List the images.

EOH
	arghelp
	cat <<EOH

Examples:

	1. knoxcli image list
		... list all the images

EOH
}

il_generic_handler()
{
	case "$1" in
		"filter" ) filter="$2" ;;
		"imagejq" ) imagejq="$2" ;;
		*) echo "UNHANDLER argopt";;
	esac
}


image_list_cmd()
{
	arginit
	argopt 	--lopt "filter" --sopt "f" --needval --handler "il_generic_handler" \
			--desc "filter to be used with image list"

	argopt 	--lopt "imagejq" --needval --handler "il_generic_handler" \
			--desc "jq based filter to use with image list"

	argopt	--sopt "h" --lopt "help" --handler "il_help" \
			--desc "help for cluster list"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1

	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	echo $json_string | jq -r "$clusterjq"
	[[ $show_nodes -eq 0 ]] && return
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
		cluster_list_get_node_list
	done < <(echo $json_string | jq -r '.[] | "\(.ID) \(.ClusterName)"')
}

