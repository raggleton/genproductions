#/bin/bash

# example usage:
# calculateXSectionAndFilterEfficiency.sh -f datasets.txt -c Moriond17 -d MINIAODSIM -n 1000000 (-m)
# documentation
# https://twiki.cern.ch/twiki/bin/viewauth/CMS/HowToGenXSecAnalyzer#Automated_scripts_to_compute_the

# To obtain CERN SSO credentials (necessary to read from McM):
#   ./getCookie.sh

FILE='datasets.txt'
CAMPAIGN='Moriond17'
DATATIER='MINIAODSIM'
EVENTS='1000000'
MCM=False
SKIPEXISTING=False
QUEUE=''
RELEASE=''

DEBUG=False
# DEBUG=True

while getopts f:c:d:n:m:s:q:r option
do
    case "${option}"
    in
            f) FILE=${OPTARG};;
            c) CAMPAIGN=${OPTARG};;
            d) DATATIER=${OPTARG};;
            n) EVENTS=${OPTARG};;
            m) MCM=True;;
            s) SKIPEXISTING=True;;
            q) QUEUE=${OPTARG};;
            r) RELEASE=${OPTARG};;
    esac
done

while read -r dataset
do
    name="$dataset"
    echo "Name read from file - $name"
    
    process_string='compute_cross_section.py -f '${dataset}' -c '${CAMPAIGN}' -n '${EVENTS}' -d '${DATATIER}' --mcm "'${MCM}'" --skipexisting "'${SKIPEXISTING}'" --debug "'${DEBUG}'"'
    # echo 'compute_cross_section.py -f '${dataset}' -c '${CAMPAIGN}' -n '${EVENTS}' -d '${DATATIER}' --mcm "'${MCM}'" --skipexisting "'${SKIPEXISTING}'" --debug "'${DEBUG}'"'
    echo ${process_string}
    
    if [[ $QUEUE != "" ]]; then
        echo "QUEUE "$QUEUE
        PRIMARY_DATASET_NAME=$(echo $dataset | tr "/" "\n" )
        PRIMARY_DATASET_NAME=$(echo $PRIMARY_DATASET_NAME | awk '{print $1;}')
        echo $PRIMARY_DATASET_NAME
        cp submit_demo.sh submit_${PRIMARY_DATASET_NAME}.sh
        chmod 755 submit_${PRIMARY_DATASET_NAME}.sh
        process_string="python ${process_string} | eval"
        echo "${process_string}" >> submit_${PRIMARY_DATASET_NAME}.sh
        bsub -q $QUEUE -u ciaociao1 submit_${PRIMARY_DATASET_NAME}.sh
    else 
    
        output=$(python ${process_string})
        output=${output#*.txt}
        
        if [ "${DEBUG}" != "True" ]; then
            if [[ $output == *"cmsRun"* ]]; then
                echo ${output}
                eval ${output}
            else
                echo ${output}
            fi
        else
            echo 'process_string'
            echo ${output}
            exit 1
        fi
    fi
    echo ""
    
done < "$FILE"


