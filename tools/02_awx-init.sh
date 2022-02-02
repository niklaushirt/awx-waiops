#!/bin/bash
echo "*****************************************************************************************************************************"
echo " 🐥 CloudPak for Watson AIOPs - Install AWX"
echo "*****************************************************************************************************************************"
echo "  "
echo ""
echo ""

echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Check if AWX is ready"
while [ `oc get pods -n awx| grep postgres|grep 1/1 | wc -l| tr -d ' '` -lt 1 ]
do
      echo "       AWX not ready yet. Waiting 15 seconds"
      sleep 15
done

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🛠️  Initialisation"
export AWX_ROUTE=$(oc get route -n awx awx -o jsonpath={.spec.host})
export ADMIN_USER=admin
export ADMIN_PASSWORD=$(oc -n awx get secret awx-admin-password -o jsonpath='{.data.password}' | base64 --decode && echo)
export OCP_URL=https://c108-e.eu-gb.containers.cloud.ibm.com:30840
export OCP_TOKEN=CHANGE-ME

export AWX_REPO=https://github.com/niklaushirt/awx-waiops.git
export RUNNER_IMAGE=niklaushirt/cp4waiops-awx:0.1.1

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🛠️  Parameters"
echo "        🧔 ADMIN_USER:$ADMIN_USER"
echo "        🔐 ADMIN_PASSWORD:$ADMIN_PASSWORD"
echo "        🌏 AWX_ROUTE:$AWX_ROUTE"
echo ""

export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/projects/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure -H 'content-type: application/json' -d $'{"name": "CP4WAIOPS Project","description": "CP4WAIOPS Project","local_path": "","scm_type": "git","scm_url": "'$AWX_REPO'","scm_branch": "","scm_refspec": "","scm_clean": false,"scm_track_submodules": false,"scm_delete_on_update": false,"credential": null,"timeout": 0,"organization": 1,"scm_update_on_launch": false,"scm_update_cache_timeout": 0,"allow_override": false,"default_environment": null}')
echo $result


sleep 600000




echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Project"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/projects/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "CP4WAIOPS Project",
    "description": "CP4WAIOPS Project",
    "local_path": "",
    "scm_type": "git",
    "scm_url": "'$AWX_REPO'",
    "scm_branch": "",
    "scm_refspec": "",
    "scm_clean": false,
    "scm_track_submodules": false,
    "scm_delete_on_update": false,
    "credential": null,
    "timeout": 0,
    "organization": 1,
    "scm_update_on_launch": false,
    "scm_update_cache_timeout": 0,
    "allow_override": false,
    "default_environment": null
}')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Project created: "$(echo $result|jq ".created")
    export PROJECT_ID=$(echo $result|jq ".id")
fi



echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Inventory"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/inventories/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "CP4WAIOPS Install",
    "description": "CP4WAIOPS Install",
    "organization": 1,
    "project": '$PROJECT_ID',
    "kind": "",
    "host_filter": null,
    "variables": "---\nOCP_LOGIN: false\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'\n#ENTITLED_REGISTRY_KEY: changeme"
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
echo "      Inventory created: "$(echo $result|tr -d '\n'|jq ".created")
export INVENTORY_ID=$(echo $result|tr -d '\n'|jq ".id")
fi



echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Executon Environment"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/execution_environments/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "CP4WAIOPS Execution Environment",
    "description": "CP4WAIOPS Execution Environment",
    "organization": null,
    "image": "'$RUNNER_IMAGE'",
    "credential": null,
    "pull": "missing"
}')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
echo "      Executon Environment created: "$(echo $result|jq ".created")
export EXENV_ID=$(echo $result|jq ".id")
fi 

sleep 15


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install CP4WAIOPS AI Manager with Demo content"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "10_Install CP4WAIOPS AI Manager with Demo content",
    "description": "Install CP4WAIOPS AI Manager with Demo content",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/10_install-cp4waiops_ai_manager_only_with_demo.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install CP4WAIOPS AI Event Manager"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install CP4WAIOPS AI Event Manager",
    "description": "11_Install CP4WAIOPS AI Event Manager",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/11_install-cp4waiops_event_manager.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Get CP4WAIOPS Logins"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Get CP4WAIOPS Logins",
    "description": "90_Get CP4WAIOPS Logins",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/90_aiops-logins.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Rook Ceph"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "14_Install Rook Ceph",
    "description": "Install Rook Ceph",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/14_install-rook-ceph.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 




echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install LDAP"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "15_Install LDAP",
    "description": "Install LDAP and register users",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/15_install-ldap.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 




echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install RobotShop"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "16_Install RobotShop",
    "description": "Install RobotShop",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/16_install-robot-shop.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install CP4WAIOPS Demo UI"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "17_Install CP4WAIOPS Demo UI",
    "description": "Install CP4WAIOPS Demo UI",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/17_aiops-demo-ui.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Toolbox"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "18_Install CP4WAIOPS Toolbox",
    "description": "Install CP4WAIOPS Demo UI",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/18_aiops-toolbox.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Turbonomic"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "20_Install Turbonomic",
    "description": "Install Turbonomic",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/20_install-turbonomic.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Humio"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "21_Install Humio",
    "description": "Install Humio",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/21_install-humio.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install ELK"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "22_Install ELK",
    "description": "Install ELK",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/22_install-elk-ocp.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install AWX"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "22_Install AWX",
    "description": "Install AWX",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/23_install-awx.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install ManageIQ"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "24_Install ManageIQ",
    "description": "Install ManageIQ",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/24_install-manageiq.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install ServiceMesh"
export result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "29_Install ServiceMesh",
    "description": "Install ServiceMesh",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "ansible/29_install-servicemesh.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

if [[ $result =~ " already exists" ]];
then
    echo "      Already exits."
else
    echo "      Job created: "$(echo $result|jq ".created")
fi 



echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀 AWX "
echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    "
echo "            📥 AWX :"
echo ""
echo "                🌏 URL:      $AWX_URL"
echo "                🧑 User:     admin"
echo "                🔐 Password: $(oc -n awx get secret awx-admin-password -o jsonpath='{.data.password}' | base64 --decode && echo)"
echo "    "
echo "    "
