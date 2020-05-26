#!/bin/bash

FILEPATH=${TEXTFILE_PATH:=/shared_vol}
INTERVAL=${COLLECT_INTERVAL:=10}
PROVISIONERS=${PROVISIONER_WHITELIST:=openebs.io/local}

## calculate_pv_capacity obtains the size of a PV in bytes
function calculate_pv_capacity(){

  if [[ ${size_in_spec} =~ "i" ]]; then
    unit=$(echo "${size_in_spec: -2}")
  else
    unit=$(echo "${size_in_spec: -1}")
  fi  

  case "${unit}" in 
  
  g|gi) echo $((1024*1024*1024*$(echo $1 | tr -d ${unit})))
     ;;
  m|mi) echo $((1024*1024*$(echo $1 | tr -d ${unit})))
     ;;
  k|ki) echo $((1024*$(echo $1 | tr -d ${unit})))
     ;;
  b|bi) echo $1 | tr -d ${unit}
     ;;
  *) echo 0
     ;;
  esac
}

## collect_pv_capacity_metrics collects the PV capacity metrics
function collect_pv_capacity_metrics(){
 
  ##TODO: We clear the file and then proceed to derive the metrics in the for loop below.
  ## If, the block below takes time, it may cause a few seconds of "no-metrics". 
  ## This needs to be optimized. Preferable approach is to replace values v/s recreating the file.  
  > ${FILEPATH}/pv_size.prom

  for i in ${pv_list[@]}
  do
    pvc_name=$(kubectl get pv ${i} -o custom-columns=:spec.claimRef.name --no-headers | tr '[:upper:]' '[:lower:]')
    size_in_spec=$(kubectl get pv ${i} -o custom-columns=:spec.capacity.storage --no-headers | tr '[:upper:]' '[:lower:]')
    size_in_bytes=$(calculate_pv_capacity ${size_in_spec};)
    echo "pv_capacity_bytes{persistentvolume=\"${i}\",persistentvolumeclaim=\"${pvc_name}\"} ${size_in_bytes}" >> ${FILEPATH}/pv_size.prom
  done
}

## collect_pv_utilization_metrics collects the PV utilization metrics
function collect_pv_utilization_metrics(){

  ##TODO: We clear the file and then proceed to derive the metrics in the for loop below.
  ## If, the block below takes time, it may cause a few seconds of "no-metrics". 
  ## This needs to be optimized. Preferable approach is to replace values v/s recreating the file.  
  > ${FILEPATH}/pv_used.prom

  declare -a pv_mount_list=()

  for i in ${pv_list[@]}
  do
    pv_mount_list+=($(findmnt --df | grep ${i} | grep '/var/lib/kubelet/pods' | head -1 | awk '{print $NF}'))
  done

  echo "mount list: ${pv_mount_list[@]}"
  for i in ${pv_mount_list[@]}
  do
    ## Get mount point utilization in bytes
    mount_data=$(du -sb ${i})
    utilization=$(echo ${mount_data}| cut -d " " -f 1)
    pv_name=$(basename $(echo ${mount_data} | cut -d " " -f 2))
    pvc_name=$(kubectl get pv ${pv_name} -o custom-columns=:spec.claimRef.name --no-headers | tr '[:upper:]' '[:lower:]')
    echo "pv_utilization_bytes{persistentvolume=\"${pv_name}\",persistentvolumeclaim=\"${pvc_name}\"} ${utilization}" >> ${FILEPATH}/pv_used.prom
  done
}

while true
do
  provisioner_list=$(echo ${PROVISIONERS} | tr ',' ' ')
  declare -a pv_list=()

  ## Select only those PVs that are bound. Several stale PVs can exist.
  for i in $(kubectl get pv -o jsonpath='{.items[?(@.status.phase=="Bound")].metadata.name}')
  do
    ## Select only those PVs that are provisioned by the whitelisted provisioners
    ## Nested conditions in jsonpath filters are not supported yet. Ref: https://github.com/kubernetes/kubernetes/issues/20352
    if [[ ${provisioner_list} =~ $(kubectl get pv ${i} -o jsonpath='{.metadata.annotations.pv\.kubernetes\.io/provisioned-by}') ]]
    then      
      pv_list+=(${i})
    fi
  done

  echo "No. of PVs by specified provisioners: ${#pv_list[@]}"

  if [[ ${#pv_list[@]} -ne 0 ]]; then
    echo "PV List: ${pv_list[@]}"
    collect_pv_capacity_metrics;
    collect_pv_utilization_metrics;
  fi

  sleep ${INTERVAL}
done
