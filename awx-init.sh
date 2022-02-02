echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "      __________  __ ___       _____    ________            "
echo "     / ____/ __ \/ // / |     / /   |  /  _/ __ \____  _____"
echo "    / /   / /_/ / // /| | /| / / /| |  / // / / / __ \/ ___/"
echo "   / /___/ ____/__  __/ |/ |/ / ___ |_/ // /_/ / /_/ (__  ) "
echo "   \____/_/      /_/  |__/|__/_/  |_/___/\____/ .___/____/  "
echo "                                             /_/            "
echo ""
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
export OCP_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCIxxxxxTEUifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlbW8tYWRtaW4tdG9rZW4tZ2p2NnMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGVtby1hZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjJiYTYzN2JiLTQxM2ItNGIxNi04NmViLTdhMGRiMDAzNzIzZCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmRlbW8tYWRtaW4ifQ.ZV52WPPkM9LKYAD2_2bHTTtkVqKoxmlceAIp-gM3HJ5SICUdm2xgNQHECSdext6kqyPgJq11iWPAt6vz1c5IUW-NgcLnu1pvYP_lpSNeFR8n2HKYVhnU4ddqzkmWojPjgVJbIYQ_2tJEsm8Ke5tKe_ydjx1Up5nn0Zq5-s_C94bjiNlvISgYgE89iATmkqN5v6Bf8aISMZUeoM0SEOVllbbSImcRzWbB6j9MCy2U6SI0cET7ye6nArU0DzIIADUczYzAHmkuXtVjgMX_6wtbBYRfTiZTYTA8suN97dhBfR-I7JkZYrbzhwQOWqr3eqCvmF2tbCKoWihJuQVryTuPrw

export AWX_REPO=https://github.com/niklaushirt/awx-waiops.git
export RUNNER_IMAGE=niklaushirt/cp4waiops-awx:0.1.1

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🛠️  Parameters"
echo "        🧔 ADMIN_USER:$ADMIN_USER"
echo "        🔐 ADMIN_PASSWORD:$ADMIN_PASSWORD"
echo "        🌏 AWX_ROUTE:$AWX_ROUTE"
echo ""



echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Project"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/projects/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
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

echo "      Project created: "$(echo $result|jq ".created")
export PROJECT_ID=$(echo $result|jq ".id")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Inventory"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/inventories/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "CP4WAIOPS Install",
    "description": "CP4WAIOPS Install",
    "organization": 1,
    "project": '$PROJECT_ID',
    "kind": "",
    "host_filter": null,
    "variables": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'\n#ENTITLED_REGISTRY_KEY: changeme"
}
')

echo "      Inventory created: "$(echo $result|tr -d '\n'|jq ".created")
export INVENTORY_ID=$(echo $result|tr -d '\n'|jq ".id")




echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Executon Environment"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/execution_environments/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "CP4WAIOPS Execution Environment",
    "description": "CP4WAIOPS Execution Environment",
    "organization": null,
    "image": "'$RUNNER_IMAGE'",
    "credential": null,
    "pull": "missing"
}')

echo "      Executon Environment created: "$(echo $result|jq ".created")
export EXENV_ID=$(echo $result|jq ".id")

sleep 15


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install CP4WAIOPS AI Manager with Demo content"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "10_Install CP4WAIOPS AI Manager with Demo content",
    "description": "Install CP4WAIOPS AI Manager with Demo content",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "10_install-cp4waiops_ai_manager_only_with_demo.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install CP4WAIOPS AI Event Manager"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install CP4WAIOPS AI Event Manager",
    "description": "11_Install CP4WAIOPS AI Event Manager",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "11_install-cp4waiops_event_manager.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Get CP4WAIOPS Logins"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Get CP4WAIOPS Logins",
    "description": "90_Get CP4WAIOPS Logins",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "90_aiops-logins.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Rook Ceph"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "14_Install Rook Ceph",
    "description": "Install Rook Ceph",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "14_install-rook-ceph.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")





echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install LDAP"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "15_Install LDAP",
    "description": "Install LDAP and register users",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "15_install-ldap.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")





echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install RobotShop"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "16_Install RobotShop",
    "description": "Install RobotShop",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "16_install-robot-shop.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install CP4WAIOPS Demo UI"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "17_Install CP4WAIOPS Demo UI",
    "description": "Install CP4WAIOPS Demo UI",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "17_aiops-demo-ui.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")



echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Toolbox"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "18_Install CP4WAIOPS Toolbox",
    "description": "Install CP4WAIOPS Demo UI",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "18_aiops-toolbox.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Turbonomic"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "20_Install Turbonomic",
    "description": "Install Turbonomic",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "20_install-turbonomic.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")



echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install Humio"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "21_Install Humio",
    "description": "Install Humio",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "21_install-humio.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")



echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install ELK"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "22_Install ELK",
    "description": "Install ELK",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "22_install-elk-ocp.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install AWX"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "22_Install AWX",
    "description": "Install AWX",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "23_install-awx.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install ManageIQ"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "24_Install ManageIQ",
    "description": "Install ManageIQ",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "24_install-manageiq.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")



echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Job: Install ServiceMesh"
result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "29_Install ServiceMesh",
    "description": "Install ServiceMesh",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "29_install-servicemesh.yaml",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo "      Job created: "$(echo $result|jq ".created")



exit 1






























result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install xxxxx",
    "description": "Install xxxxx",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "xxxxx",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo $result



result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install xxxxx",
    "description": "Install xxxxx",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": '$PROJECT_ID',
    "playbook": "xxxxx",
    "scm_branch": "",
    "extra_vars": "",
    "execution_environment": '$EXENV_ID'
}
')

echo $result







exit 1


00_config_cp4waiops.yaml
10_install-cp4waiops_ai_manager-optimised.yaml
10_install-cp4waiops_ai_manager_all.yaml
10_install-cp4waiops_ai_manager_only.yaml
10_install-cp4waiops_ai_manager_only_with_demo.yaml
11_install-cp4waiops_event_manager.yaml
14_install-rook-ceph.yaml
18_aiops-demo-ui.yaml
18_install-ldap.yaml
18_install-robot-shop.yaml
19_aiops-event-webhook.yaml
20_1_aiops-addons-kubeturbo.yaml
20_2_aiops-addons-turbonomic-metrics.yaml
20_3_aiops-addons-turbonomic-gateway.yaml
20_install-turbonomic.yaml
21_install-humio.yaml
22_install-elk-ocp.yaml
23_install-awx.yaml
24_install-manageiq.yaml
29_install-servicemesh.yaml
40_aiops-post-ldap-register.yaml
90_aiops-logins.yaml



result=$(curl -X "POST" -s "https://$AWX_ROUTE/api/v2/credentials/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "tttt111",
    "description": "",
    "organization": null,
    "credential_type": 16,
    "user": 1,
    "team": null,
    "inputs": {
        "host": "'$OCP_URL'",
        "verify_ssl": false,
        "bearer_token": "'$OCP_TOKEN'"
    },
    "kind": "kubernetes_bearer_token"
}')

echo $result


curl -X "GET" "https://$AWX_ROUTE/api/v1/authtoken/" 

export user=admin
export password=passw0rd

curl -k -u $user:$password -X GET "https://$AWX_ROUTE/api/v2/hosts"




export CLUSTER_NAME=itzroks-270003bu3k-o3v0m0-6ccd7f378ae819553d37d5f2ee142bd6-0000.eu-gb.containers.appdomain.cloud
curl -X "POST" -s "https://$AWX_ROUTE/api/v2/projects/" -u 'admin:passw0rd' --insecure \
-H 'content-type: application/json' \
-d $'{
    "id": 99,
    "name": "API2",
    "description": "API",
    "local_path": "",
    "scm_type": "git",
    "scm_url": "https://github.com/niklaushirt/awx-waiops.git",
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
}'







{
    "name": "API",
    "description": "API",
    "local_path": "",
    "scm_type": "git",
    "scm_url": "https://github.com/niklaushirt/awx-waiops.git",
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
}




https://awx-awx.itzroks-270003bu3k-o3v0m0-6ccd7f378ae819553d37d5f2ee142bd6-0000.eu-gb.containers.appdomain.cloud/api/v2/execution_environments/

{
    "name": "API",
    "description": "API",
    "organization": null,
    "image": "niklaushirt/cp4waiops-tools:awx-runner",
    "credential": null,
    "pull": "missing"
}




https://awx-awx.itzroks-270003bu3k-o3v0m0-6ccd7f378ae819553d37d5f2ee142bd6-0000.eu-gb.containers.appdomain.cloud/api/v2/job_templates/

{
    "name": "API",
    "description": "API",
    "job_type": "run",
    "inventory": '$INVENTORY_ID',
    "project": 10,
    "playbook": "90_aiops-logins.yaml",
    "scm_branch": "",
    "forks": 0,
    "limit": "",
    "verbosity": 0,
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: https://c108-e.eu-gb.containers.cloud.ibm.com:30840\nOCP_TOKEN: eyJhbGciOiJSUzI1NiIsImtpZCI6Ilc4R0w5aE03bDdlYVdVZEI1WUhMLXc1bmhSZW1HZVkxSnl3RjVXVFUwTEUifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlbW8tYWRtaW4tdG9rZW4tZ2p2NnMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGVtby1hZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjJiYTYzN2JiLTQxM2ItNGIxNi04NmViLTdhMGRiMDAzNzIzZCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmRlbW8tYWRtaW4ifQ.ZV52WPPkM9LKYAD2_2bHTTtkVqKoxmlceAIp-gM3HJ5SICUdm2xgNQHECSdext6kqyPgJq11iWPAt6vz1c5IUW-NgcLnu1pvYP_lpSNeFR8n2HKYVhnU4ddqzkmWojPjgVJbIYQ_2tJEsm8Ke5tKe_ydjx1Up5nn0Zq5-s_C94bjiNlvISgYgE89iATmkqN5v6Bf8aISMZUeoM0SEOVllbbSImcRzWbB6j9MCy2U6SI0cET7ye6nArU0DzIIADUczYzAHmkuXtVjgMX_6wtbBYRfTiZTYTA8suN97dhBfR-I7JkZYrbzhwQOWqr3eqCvmF2tbCKoWihJuQVryTuPrw",
    "job_tags": "",
    "force_handlers": false,
    "skip_tags": "",
    "start_at_task": "",
    "timeout": 0,
    "use_fact_cache": false,
    "execution_environment": 3,
    "host_config_key": "",
    "ask_scm_branch_on_launch": false,
    "ask_diff_mode_on_launch": false,
    "ask_variables_on_launch": false,
    "ask_limit_on_launch": false,
    "ask_tags_on_launch": false,
    "ask_skip_tags_on_launch": false,
    "ask_job_type_on_launch": false,
    "ask_verbosity_on_launch": false,
    "ask_inventory_on_launch": false,
    "ask_credential_on_launch": false,
    "survey_enabled": false,
    "become_enabled": false,
    "diff_mode": false,
    "allow_simultaneous": false,
    "job_slice_count": 1,
    "webhook_service": null,
    "webhook_credential": null
}



"created": "2022-02-01T11:06:06.053643Z",
"modified": "2022-02-01T11:21:52.837645Z",
"name": "Get Logins",
"description": "",
"job_type": "run",
"inventory": '$INVENTORY_ID',
"project": 10,
"playbook": "90_aiops-logins.yaml",
"scm_branch": "",
"forks": 0,
"limit": "",
"verbosity": 0,
"extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: https://c108-e.eu-gb.containers.cloud.ibm.com:30840\nOCP_TOKEN: eyJhbGciOiJSUzI1NiIsImtpZCI6Ilc4R0w5aE03bDdlYVdVZEI1WUhMLXc1bmhSZW1HZVkxSnl3RjVXVFUwTEUifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlbW8tYWRtaW4tdG9rZW4tZ2p2NnMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGVtby1hZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjJiYTYzN2JiLTQxM2ItNGIxNi04NmViLTdhMGRiMDAzNzIzZCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmRlbW8tYWRtaW4ifQ.ZV52WPPkM9LKYAD2_2bHTTtkVqKoxmlceAIp-gM3HJ5SICUdm2xgNQHECSdext6kqyPgJq11iWPAt6vz1c5IUW-NgcLnu1pvYP_lpSNeFR8n2HKYVhnU4ddqzkmWojPjgVJbIYQ_2tJEsm8Ke5tKe_ydjx1Up5nn0Zq5-s_C94bjiNlvISgYgE89iATmkqN5v6Bf8aISMZUeoM0SEOVllbbSImcRzWbB6j9MCy2U6SI0cET7ye6nArU0DzIIADUczYzAHmkuXtVjgMX_6wtbBYRfTiZTYTA8suN97dhBfR-I7JkZYrbzhwQOWqr3eqCvmF2tbCKoWihJuQVryTuPrw",
"job_tags": "",
"force_handlers": false,
"skip_tags": "",
"start_at_task": "",
"timeout": 0,
"use_fact_cache": false,
"organization": 1,
"last_job_run": "2022-02-01T13:20:15.580538Z",
"last_job_failed": false,
"next_job_run": null,
"status": "successful",
"execution_environment": 3,
"host_config_key": "",
"ask_scm_branch_on_launch": false,
"ask_diff_mode_on_launch": false,
"ask_variables_on_launch": false,
"ask_limit_on_launch": false,
"ask_tags_on_launch": false,
"ask_skip_tags_on_launch": false,
"ask_job_type_on_launch": false,
"ask_verbosity_on_launch": false,
"ask_inventory_on_launch": false,
"ask_credential_on_launch": false,
"survey_enabled": false,
"become_enabled": false,
"diff_mode": false,
"allow_simultaneous": false,
"custom_virtualenv": null,
"job_slice_count": 1,
"webhook_service": "",
"webhook_credential": null




curl -X "POST" -s "https://evtmanager-topology.{{ WAIOPS_NAMESPACE }}.{{ CLUSTER_NAME.stdout_lines[0] }}/1.0/merge/rules?ruleType=matchTokensRule" --insecure \
-H 'X-TenantID: cfd95b7e-3bc7-4006-a4a8-a73a79c71255' \
-H 'content-type: application/json' \
-u {{ EVTMGR_LOGIN.stdout_lines[0] }} \
-d $'{
      "tokens": [
        "name"
      ],
      "entityTypes": [
        "deployment"
      ],
      "providers": [
        "*"
      ],
      "observers": [
        "*"
      ],
      "ruleType": "mergeRule",
      "name": "merge-name-type",
      "ruleStatus": "enabled"
    }'
