echo "*****************************************************************************************************************************"
echo " 🐥 CloudPak for Watson AIOPs - Install AWX"
echo "*****************************************************************************************************************************"
echo "  "
echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create Clusterrole binding"
oc create clusterrolebinding awx-default --clusterrole=cluster-admin --serviceaccount=awx:default| sed 's/^/      /'

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Operator"
oc apply -f ./templates/awx/operator-install.yaml| sed 's/^/      /'

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🚀  Create AWX Instance"
oc apply -f ./templates/awx/awx-deploy-cr.yml| sed 's/^/      /'

echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🕦  Wait for AWX pods ready"
while [ `oc get pods -n awx| grep postgres|grep 1/1 | wc -l| tr -d ' '` -lt 1 ]
do
      echo "       AWX not ready yet. Waiting 15 seconds"
      sleep 15
done


echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🕦  Wait for AWX being ready"
READY=$(curl wget https://awx-awx.itzroks-270003bu3k-rsesse-6ccd7f378ae819553d37d5f2ee142bd6-0000.eu-gb.containers.appdomain.cloud/api)
while [ $READY =~ "Application is not available" ]
do
      echo "       AWX not ready yet. Waiting 15 seconds"
      READY=$(curl wget https://awx-awx.itzroks-270003bu3k-rsesse-6ccd7f378ae819553d37d5f2ee142bd6-0000.eu-gb.containers.appdomain.cloud/api)

      sleep 15
done


echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀 AWX "
echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
echo "    "
echo "            📥 AWX :"
echo ""
echo "                🌏 URL:      https://$(oc get route -n awx awx -o jsonpath={.spec.host})"
echo "                🧑 User:     admin"
echo "                🔐 Password: $(oc -n awx get secret awx-admin-password -o jsonpath='{.data.password}' | base64 --decode && echo)"
echo "    "
echo "    "



exit 1

#oc delete -f ./templates/awx/awx-deploy-cr.yml
#oc delete -f ./templates/awx/operator-install.yaml
