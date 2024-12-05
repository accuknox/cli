framework=""
compliancejq="."
result=""

cl_help()
{
	cat <<EOH
### [compliance list] options
List the compliances.

EOH
	arghelp
	cat <<EOH

Examples:

	1. knoxcli compliance list
		... list all the compliance checks
	2. knoxcli compliance list --framework SOC-3 --compliancejq '.results[].asset.type | select (.name == "aws_account")'
		... list all the SOC 3 compliance check results performed on aws accounts

Options:
	-f, --framework The compliance framework to list in quotations
	-r, --result Filter the compliance checks to view only those with a particular result. Value can be FAILED, PASSED, WARNING or NOT_AVAILABLE

#### Compliance Frameworks list
1  APRA 234 STANDARD
2  AWS CIS Benchmark v1.4.0
3  AWS CIS Benchmark v1.5.0
4  AWS CIS Benchmark v2.0.0
5  AWS Well-Architected Framework - Security
6  BAIT
7  California Consumer Privacy Act (CCPA)
8  COPPA
9  CSPM Encryption Program
10  FedRamp
11  FERPA
12  FISMA
13  GCP CIS Benchmarks v1.2.0
14  GCP CIS Benchmark v2.0.0
15  General Data Protection Regulation (GDPR) EU
16  HIPAA
17  HITRUST CSF
18  ISMS-P for AWS
19  ISO 27001
20  ISO 27017
21  ISO 27018
22  Korean Financial Security Agency Guidelines
23  LGPD
24  Mitre AWS Attack Framework
25  NIST 800-171
26  NIST CSF
27  NIST SP 800-53
28  PCI
29  SOC 2 Type II
30  SOC 3
31  VAIT
EOH
}

cl_generic_handler()
{
	case "$1" in
		"framework" ) case "$2" in
			"AwsWellArchitectedFramework" ) framework="AWS%20Well-Architected%20Framework%20-%20Security" ;;
			* ) framework="$(echo "$2" | sed 's/\s/%20/g')" ;;
			esac 
			compliancejq='del(.results[].control.benchmark[] | select (.program_name != "'"$2"'"))'
			;;
		"result" ) result="&result=$2" ;;
		"compliancejq" ) compliancejq="$2" ;;
		*) echo "UNHANDLER argopt";;
	esac
}


compliance_list_cmd()
{
	arginit
	argopt 	--lopt "framework" --sopt "f" --needval --handler "cl_generic_handler" \
			--desc "filter to be used with compliance list"

	argopt 	--lopt "compliancejq" --needval --handler "cl_generic_handler" \
			--desc "jq based filter to use with compliance list"

	argopt	--sopt "h" --lopt "help" --handler "cl_help" \
			--desc "help for compliance list"

	argopt 	--lopt "result" --sopt "r" --needval --handler "cl_generic_handler" \
			--desc "filter the compliance findings list based on the result. Value can be FAILED, PASSED, WARNING or NOT_AVAILABLE"

	argrun "$@"
	[[ $? -ne 0 ]] && return 1

	ak_api "$CSPM_URL/api/v1/checks?page=1&page_size=20&last_scan=true&program_name=$framework$result"
	#ak_api "$CSPM_URLhttps://cspm.demo.accuknox.com/api/v1/checks?page=1&page_size=20&last_scan=true&program_name=AWS%20Well-Architected%20Framework%20-%20Security&result=FAILED"
	echo $json_string | jq -r "$compliancejq"
}

