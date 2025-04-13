#!/bin/bash

# To set .accuknox.cfg check https://github.com/accuknox/tools/tree/main/api-samples
. ${ACCUKNOX_CFG:-~/.accuknox.cfg}
. util.sh

# Other params
TMP=$DIR/$(basename $0)
clusterspec=".*" # regex for cluster names

usage() { 
  echo "Usage: $0 " 1>&2
  echo "  -f  <json filter list>" 1>&2
  echo "  -p  <page number>" 1>&2
  echo "  -g <per page>" 1>&2
  echo "  -t <from time>" 1>&2
  echo "  -e <to time>" 1>&2
  echo "  -c  <cluster name>" 1>&2
  echo "  -v  <any string for verbose>" 1>&2
  echo 1>&2;
  echo -n "Example: ./getAlerts.sh -f " 1>&2
  echo -n "'{\"field\": \"Action\", \"value\": \"Block\", \"op\": \"match\"}'" 1>&2
  echo ' -p 1 -g 100 -t $(date +%s) -e $(( $(date +%s) - 86400)) -c "nrs"' 1>&2
  exit 1; 
}

# api url
# https://cwpp.nrs.accuknox.com/monitors/v1/alerts/events?orderby=desc

# api response example
#{
#  "Namespace": [],
#  "FromTime": 1742426700,
#  "ToTime": 1743031500,
#  "PageId": 1,
#  "PageSize": 20,
#  "Filters": [
#    {
#      "field": "Action",
#      "value": "Audit",
#      "op": "match"
#    },
#    {
#      "field": "Source",
#      "value": "/usr/sbin/sshd",
#      "op": "match"
#    }
#  ],
#  "ClusterID": [],
#  "View": "List",
#  "Type": "kubearmor",
#  "WorkloadType": [],
#  "WorkloadName": [],
#  "WorkspaceID": 63,
#  "LogType": "active"
#}

# api error examples
# {"errors":"Key: 'AlertsLog.ClusterID' Error:Field validation for 'ClusterID' failed on the 'required' tag\n
# Key: 'AlertsLog.PageID' Error:Field validation for 'PageID' failed on the 'required' tag\n
# Key: 'AlertsLog.PageSize' Error:Field validation for 'PageSize' failed on the 'required' tag\n
# Key: 'AlertsLog.FromTime' Error:Field validation for 'FromTime' failed on the 'required' tag\n
# Key: 'AlertsLog.ToTime' Error:Field validation for 'ToTime' failed on the 'required' tag

while getopts ":p:e:t:f:c:g:v" o; do
  case "${o}" in
    f)
      flts=${OPTARG}
      ;;
    p)
      page=${OPTARG}
      ;;
    g)
      perPage=${OPTARG}
      ;;
    t)
      ft=${OPTARG}
      ;;
    e)
      tt=${OPTARG}
      ;;
    c)
      cluster=${OPTARG}
      ;;
    v)
      v=1
      ;;
    *)
      usage
      ;;
  esac
done

# "$flts" "$page" "$perPage" "$ft" "$tt" "$cluster" $v
if [[ "${flts}x" = "x" ]] 
then
  flts=""
fi

if [[ "${page}x" = "x" ]] 
then
  page=1
fi

if [[ "${perPage}x" = "x" ]] 
then
  perPage=100
fi

if [[ "${ft}x" = "x" ]] 
then
  ft=$( date +%s )
fi

if [[ "${tt}x" = "x" ]] 
then
  tt=$(( $ft - 86400 ))
fi

if [[ "${cluster}x" = "x" ]] 
then
  cluster="nrs"
fi

# verbose
if [[ ${v} = 1 ]]
then
  echo "f: $flts p: $page g: $perPage t: $ft e:$tt c: $cluster v: $v"
fi

get_alarm_list()
{

  flt=$1
  page=$2
  perPage=$3
  tt=$4
  ft=$5
  clus=$6
  vb=$7

  data_raw=$( jq -n \
    --argjson ft   $ft \
    --argjson tt   $tt \
    --argjson pid  $page \
    --argjson pp   $perPage \
    --argjson cid  "[\"$cid\"]" \
  '{"Namespace":[],"FromTime":$ft,"ToTime":$tt,"PageId":$pid,"PageSize":$pp,"Filters":[],"ClusterID":$cid,"View":"List","Type":"kubearmor","WorkloadType":[],"WorkloadName":[],"WorkspaceID":63,"LogType":"active"}' )

  if [[ "${flt}x" != "x" ]]
  then
    full_query=$(echo $data_raw | jq ".Filters += [${flt}]")
    data_raw=$full_query
  fi

  if [[ $vb = 1 ]]
  then
    echo
    echo
    echo $data_raw;
    echo 
    echo
  fi

	ak_api "$CWPP_URL/monitors/v1/alerts/events?orderby=desc"

	echo $json_string 
}

get_cluster_id()
{

	ak_api "$CWPP_URL/cluster-onboarding/api/v1/get-onboarded-clusters?wsid=$TENANT_ID"
	while read cline; do
		cid=${cline/ */}
		cname=${cline/* /}
    
    if [[ $cname = $6 ]]
    then
		  [[ ! $cname =~ $clusterspec ]] && echo "ignoring cluster [$cname] ..." && continue
      [[ -z $6 ]] && [[ ! $6 == $cname ]] && continue
		  get_alarm_list "$1" "$2" "$3" "$4" "$5" "$6" $7
    fi

	done < <(echo $json_string | jq -r '.[] | "\(.ID) \(.ClusterName)"')
}

main()
{	
  ak_prereq
	get_cluster_id "$1" "$2" "$3" "$4" "$5" "$6" $7
}

# start here
main "$flts" "$page" "$perPage" "$ft" "$tt" "$cluster" $v

