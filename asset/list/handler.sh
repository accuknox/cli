category=""
assetjq="."
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
1  Serviceaccount
2  Security and Identity
3  null
4  CodeArtifact
5  Configuration
6  Storage
7  Workspace
8  Developer tools
9  Compute
10  IAM
11  Workloads
12  Cluster
13  CI/CD
14  Management
15  Clusterrole
16  DocumentDB
17  Block Storage
18  Miscellaneous
19  Key management
20  IaC_bitbucket-repository
21  IaC_github-repository
22  Object Storage
23  Logging
24  Operations
25  Namespace
26  Database
27  Resource Management
28  Pipeline
29  Certificate management
30  IaC_gitlab-repository
31  IaC_harness-repository
32  IaC_localhost-repository
33  Role
34  Automation
35  Backup & disaster recovery
36  API Management
37  null_parent
38  CDN
39  Data analytics
40  Deployment
41  Networking
42  Container
43  Audit logging
44  Rolebinding
45  Security & Identity
46  IaC_my-repository
47  Clusterrolebinding
48  Container registry
49  Host
50  Cloud Account
51  User
52  Serverless
53  AI + Machine Learning
54  Host_Scan_Host
55  Backup
56  Security Monitoring
57  Software
58  IaC_IAC-Repository
EOH
}

al_generic_handler()
{
	case "$1" in
		"category" ) category="&asset_category="$( echo $2 | sed 's/\s/%20/g')"" ;;
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

