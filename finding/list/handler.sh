findingjq='del(.group_by_fields, .display_fields)'
type=""
severity=""
date_range=""

fl_help()
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
	3. knoxcli finding list --search "unused loop"
		... search all the findings list for findings with the "unused loop" keyword

Options:
	-t, --type The type of the finding data to list based on scanner
#### Finding type list
1. trivy
2. nessus
	-d, --date-range A range of dates to filter the asset list. Two dates separated by 'to' are required, they should be of format 'YYY-MM-DD' (e.g. --date-range 01-01-2000to28-03-2000)
	-s, --severity Filter the finding list based on severity. Multiple severities can be specified separated by commas
	-k, --search Search for findings in the finding list based on keywords. Value needs to be enclosed in quotation marks (e.g. --search "unused loop")
EOH
}

fl_generic_handler()
{
	case "$1" in
		"type" ) type="&data_type=$2" ;;
		"date-range" ) date_range="&last_seen_after="$(echo "$2" | sed 's/to.*//')"&last_seen_before="$(echo "$2" | sed 's/.*to//')"" ;;
		"findingjq" ) findingjq="$2" ;;
		"search" ) search="$(echo "$2" | sed 's/\s/+/g')" ;;
		"severity" ) severity="&risk_factor=$2" ;;
		*) echo "UNHANDLER argopt";;
	esac
}


finding_list_cmd()
{
	arginit
	argopt 	--lopt "type" --sopt "t" --needval --handler "fl_generic_handler" \
			--desc "filter to be used with finding list"

	argopt 	--lopt "findingjq" --needval --handler "fl_generic_handler" \
			--desc "jq based filter to use with finding list"

	argopt	--sopt "h" --lopt "help" --handler "fl_help" \
			--desc "help for finding list"

	argopt  --sopt "d" --lopt "date-range" --needval --handler "fl_generic_handler" \
		                        --desc "date filter for finding list"

	argopt 	--lopt "search" --sopt "k" --needval --handler "fl_generic_handler" \
			--desc "filter the findings list based on keywords in the finding name"

	argopt  --lopt "severity" --sopt "s" --needval --handler "fl_generic_handler" \
		                        --desc "filter finding list based on finding severity"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1

	ak_api "$CSPM_URL/api/v1/findings?page=1&search=$search&page_size=20$type$date_range$severity"
	#ak_api "$CSPM_URL/api/v1/assets?page=1&page_size=20&search=&ordering=&asset_category=Container&present_on_date_after=2024-11-20&present_on_date_before=2024-12-02"
	echo $json_string | jq -r "$findingjq"
}

