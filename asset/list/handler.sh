filter=""
assetjq=".results[] | select(.vulnerabilities.Critical >= 2)"

al_help()
{
	cat <<EOH
### [asset list] options
List the assets.

EOH
	arghelp
	cat <<EOH

Examples:

	1. knoxcli asset list
		... list all the assets
	2. knoxcli asset list --filter "asset_category=Container" --assetjq ".results[] | select(.vulnerabilities.Critical >= 3)"
		... list all the 

#### Asset Categories list
1. Container
2. Storage
EOH
}

al_generic_handler()
{
	case "$1" in
		"filter" ) filter="$2" ;;
		"assetjq" ) assetjq="$2" ;;
		*) echo "UNHANDLER argopt";;
	esac
}


asset_list_cmd()
{
	arginit
	argopt 	--lopt "filter" --sopt "f" --needval --handler "al_generic_handler" \
			--desc "filter to be used with image list"

	argopt 	--lopt "assetjq" --needval --handler "al_generic_handler" \
			--desc "jq based filter to use with asset list"

	argopt	--sopt "h" --lopt "help" --handler "al_help" \
			--desc "help for cluster list"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1

	ak_api "$CSPM_URL/api/v1/assets?page=1&page_size=20&$filter"
	#ak_api "$CSPM_URL/api/v1/assets?page=1&page_size=20&search=&ordering=&asset_category=Container"
	echo $json_string | jq -r "$assetjq"
}

