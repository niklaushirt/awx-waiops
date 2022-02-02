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
echo " 🐥 CloudPak for Watson AIOPs - Install and configure AWX in local cluster"
echo "*****************************************************************************************************************************"
echo "  "
echo ""
echo ""

#export INSTALL_REPO=https://github.com/niklaushirt/awx-waiops.git

echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🌏  Get Installer files from $INSTALL_REPO"
git clone $INSTALL_REPO| sed 's/^/      /'
cd awx-waiops/
pwd| sed 's/^/         /'


echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎  Available Playbooks"
ls -al ansible| sed 's/^/         /'

echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🔎  Available Tools"
ls -al tools| sed 's/^/         /'

echo "  "
echo ""
echo ""
echo "  "
echo ""
echo ""
echo "------------------------------------------------------------------------------------------------------------------------------"
echo "🚀  Starting Scripts"

./tools/01_awx-install.sh
./tools/02_awx-init.sh


echo "*****************************************************************************************************************************"
echo " ✅ DONE"
echo "*****************************************************************************************************************************"


#while true; do echo "Still alive"; sleep 3000;  done;
