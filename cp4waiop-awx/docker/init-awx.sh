oc delete -f ./templates/awx/awx-deploy-cr.yml
oc delete -f ./templates/awx/operator-install.yaml

oc create clusterrolebinding awx-default --clusterrole=cluster-admin --serviceaccount=awx:default

oc apply -f ./templates/awx/operator-install.yaml
oc apply -f ./templates/awx/awx-deploy-cr.yml

while [ `oc get pods -n awx| grep postgres|grep 1/1 | wc -l| tr -d ' '` -lt 1 ]
do
      echo "AWX not ready yet. Waiting 15 seconds"
      sleep 15
done

export AWX_ROUTE=$(oc get route -n awx awx -o jsonpath={.spec.host})
export ADMIN_USER=admin
export =$(oc -n awx get secret awx-admin-password -o jsonpath='{.data.password}' | base64 --decode && echo)
export OCP_URL=https://c108-e.eu-gb.containers.cloud.ibm.com:30840
export OCP_TOKEN=eyJhbGciOiJSUzI1NiIsImtxxxxxxxxxUwTEUifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRlbW8tYWRtaW4tdG9rZW4tZ2p2NnMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGVtby1hZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjJiYTYzN2JiLTQxM2ItNGIxNi04NmViLTdhMGRiMDAzNzIzZCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmRlbW8tYWRtaW4ifQ.ZV52WPPkM9LKYAD2_2bHTTtkVqKoxmlceAIp-gM3HJ5SICUdm2xgNQHECSdext6kqyPgJq11iWPAt6vz1c5IUW-NgcLnu1pvYP_lpSNeFR8n2HKYVhnU4ddqzkmWojPjgVJbIYQ_2tJEsm8Ke5tKe_ydjx1Up5nn0Zq5-s_C94bjiNlvISgYgE89iATmkqN5v6Bf8aISMZUeoM0SEOVllbbSImcRzWbB6j9MCy2U6SI0cET7ye6nArU0DzIIADUczYzAHmkuXtVjgMX_6wtbBYRfTiZTYTA8suN97dhBfR-I7JkZYrbzhwQOWqr3eqCvmF2tbCKoWihJuQVryTuPrw

echo ADMIN_USER:$ADMIN_USER
echo ADMIN_PASSWORD:$ADMIN_PASSWORD
echo AWX_ROUTE:$AWX_ROUTE

result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/projects/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "CP4WAIOPS Project",
    "description": "CP4WAIOPS Project",
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
}')


export PROJECT_ID=$(echo $result|jq ".id")




result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/execution_environments/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "CP4WAIOPS Execution Environment",
    "description": "CP4WAIOPS Execution Environment",
    "organization": null,
    "image": "niklaushirt/cp4waiops-awx:0.1.1",
    "credential": null,
    "pull": "missing"
}')


export EXENV_ID=$(echo $result|jq ".id")

sleep 15





result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Get CP4WAIOPS Logins",
    "description": "Get CP4WAIOPS Logins",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "90_aiops-logins.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result

result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install CP4WAIOPS AI Manager with Demo content",
    "description": "Install CP4WAIOPS AI Manager with Demo content",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "10_install-cp4waiops_ai_manager_only_with_demo.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result

result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install Rook Ceph",
    "description": "Install Rook Ceph",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "14_install-rook-ceph.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result

result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install CP4WAIOPS Demo UI",
    "description": "Install CP4WAIOPS Demo UI",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "18_aiops-demo-ui.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result

result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install LDAP",
    "description": "Install LDAP",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "18_install-ldap.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result


result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Register LDAP Users",
    "description": "Register LDAP Users",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "40_aiops-post-ldap-register.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result

result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install RobotShop",
    "description": "Install RobotShop",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "18_install-robot-shop.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result

result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install Turbonomic",
    "description": "Install Turbonomic",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "20_install-turbonomic.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result


result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install Humio",
    "description": "Install Humio",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "21_install-humio.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result


result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install ELK",
    "description": "Install ELK",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "22_install-elk-ocp.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result



result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install ManageIQ",
    "description": "Install ManageIQ",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "24_install-manageiq.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result



result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install ServiceMesh",
    "description": "Install ServiceMesh",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "29_install-servicemesh.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result



result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install CP4WAIOPS AI Event Manager",
    "description": "Install CP4WAIOPS AI Event Manager",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "11_install-cp4waiops_event_manager.yaml",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result


exit 1



result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install xxxxx",
    "description": "Install xxxxx",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "xxxxx",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
    "execution_environment": '$EXENV_ID'
}
')

echo $result



result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/job_templates/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
-H 'content-type: application/json' \
-d $'{
    "name": "Install xxxxx",
    "description": "Install xxxxx",
    "job_type": "run",
    "inventory": 1,
    "project": '$PROJECT_ID',
    "playbook": "xxxxx",
    "scm_branch": "",
    "extra_vars": "---\nOCP_LOGIN: true\nOCP_URL: '$OCP_URL'\nOCP_TOKEN: '$OCP_TOKEN'",
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



result=$(curl -X "POST" "https://$AWX_ROUTE/api/v2/credentials/" -u "$ADMIN_USER:$ADMIN_PASSWORD" --insecure \
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
curl -X "POST" "https://$AWX_ROUTE/api/v2/projects/" -u 'admin:passw0rd' --insecure \
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
    "inventory": 1,
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
"inventory": 1,
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




curl -X "POST" "https://evtmanager-topology.{{ WAIOPS_NAMESPACE }}.{{ CLUSTER_NAME.stdout_lines[0] }}/1.0/merge/rules?ruleType=matchTokensRule" --insecure \
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
