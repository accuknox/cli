findingjq=".results[]"
type=""
severity=""
date_range=""

fi_help()
{
	cat <<EOH
### [asset list] options
List the assets.

EOH
	arghelp
	cat <<EOH

Examples:

	1. knoxcli finding list
		... list all the findings
	2. knoxcli finding list --type sonarqube --severity Critical --date-range 2024-11-25to2024-12-01 --findingjq '.results[] | select(.status == "Active")'
		... list all active sonarqube findings that have specified severity and within the date range

Options:
	-t, --type The type of the finding data to list based on scanner
#### Finding type list
1. trivy
2. nessus
	-d, --date-range A range of dates to filter the asset list. Two dates separated by 'to' are required, they should be of format 'YYY-MM-DD' (e.g. --date-range 01-01-2000to28-03-2000)
	-s, --severity Filter the finding list based on severity. Multiple severities can be specified separated by commas
EOH
}

fi_generic_handler()
{
	case "$1" in
		"type" ) type="&data_type=$2" ;;
		"date-range" ) date_range="&last_seen_after="$(echo "$2" | sed 's/to.*//')"&last_seen_before="$(echo "$2" | sed 's/.*to//')"" ;;
		"findingjq" ) findingjq="$2" ;;
		"severity" ) severity="&risk_factor=$2" ;;
		*) echo "UNHANDLER argopt";;
	esac
}


finding_list_cmd()
{
	arginit
	argopt 	--lopt "type" --sopt "t" --needval --handler "fi_generic_handler" \
			--desc "filter to be used with finding list"

	argopt 	--lopt "findingjq" --needval --handler "fi_generic_handler" \
			--desc "jq based filter to use with finding list"

	argopt	--sopt "h" --lopt "help" --handler "fi_help" \
			--desc "help for finding list"

	argopt  --sopt "d" --lopt "date-range" --needval --handler "fi_generic_handler" \
		                        --desc "date filter for finding list"

	argopt  --lopt "severity" --sopt "s" --needval --handler "fi_generic_handler" \
		                        --desc "filter finding list based on finding severity"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1

	ak_api "$CSPM_URL/api/v1/findings?page=1&search=&page_size=20$type$date_range$severity"
	#ak_api "$CSPM_URL/api/v1/assets?page=1&page_size=20&search=&ordering=&asset_category=Container&present_on_date_after=2024-11-20&present_on_date_before=2024-12-02"
	echo $json_string | jq -r "$findingjq"
}

