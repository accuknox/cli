category=""
assetjq=".results[]"
date_range=""

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
	2. knoxcli asset list --category "Container" --assetjq ".results[] | select(.vulnerabilities.Critical >= 3)"
		... list all the Container images with 3 or more Critical vulnerabilities

Options:
	-c, --category The category of the asset to list
	-d, --date-range A range of dates to filter the asset list. Two dates separated by 'to' are required, they should be of format 'YYY-MM-DD' (e.g. --date-range 01-01-2000to28-03-2000)

#### Asset Categories list
1. Container
2. Storage
3. Compute
EOH
}

al_generic_handler()
{
	case "$1" in
		"category" ) category="&asset_category=$2" ;;
		"date-range" ) date_range="&present_on_date_after="$(echo "$2" | sed 's/to.*//')"&present_on_date_before="$(echo "$2" | sed 's/.*to//')"" ;;
		"assetjq" ) assetjq="$2" ;;
		*) echo "UNHANDLER argopt";;
	esac
}


asset_list_cmd()
{
	arginit
	argopt 	--lopt "category" --sopt "c" --needval --handler "al_generic_handler" \
			--desc "filter to be used with asset list"

	argopt 	--lopt "assetjq" --needval --handler "al_generic_handler" \
			--desc "jq based filter to use with asset list"

	argopt	--sopt "h" --lopt "help" --handler "al_help" \
			--desc "help for asset list"

	argopt  --sopt "d" --lopt "date-range" --needval --handler "al_generic_handler" \
		                        --desc "date filter for asset list"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1

	ak_api "$CSPM_URL/api/v1/assets?page=1&page_size=20$category$date_range"
	#ak_api "$CSPM_URL/api/v1/assets?page=1&page_size=20&search=&ordering=&asset_category=Container&present_on_date_after=2024-11-20&present_on_date_before=2024-12-02"
	echo $json_string | jq -r "$assetjq"
}

