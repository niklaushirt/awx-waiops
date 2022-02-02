<center> <h1>CP4WatsonAIOps V3.2</h1> </center>
<center> <h2>Demo Environment Installation with AWX</h2> </center>



<center> ©2022 Niklaus Hirt / IBM </center>



<div style="page-break-after: always;"></div>


### ❗ THIS IS WORK IN PROGRESS
Please drop me a note on Slack or by mail nikh@ch.ibm.com if you find glitches or problems.


# Changes

| Date  | Description  | Files  | 
|---|---|---|
|  02.01.2022 | First Draft |  |

<div style="page-break-after: always;"></div>


---------------------------------------------------------------
# 🐥 1. Easy Install
---------------------------------------------------------------

## 1.1. Platform Install - AWX


Please create the following two elements in your OCP cluster.


### 1.1.1. Command Line install

You can run run:

```bash
oc apply -n default -f create-installer.yaml

or

kubectl apply -n default -f create-installer.yaml

```


### 1.1.2. Web UI install

Or you can create them through the OCP Web UI:

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: installer-default-default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: default
    namespace: default
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cp4waiops-installer
  namespace: default
  labels:
      app: cp4waiops-installer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cp4waiops-installer
  template:
    metadata:
      labels:
        app: cp4waiops-installer
    spec:
      containers:
      - image: niklaushirt/cp4waiops-installer:1.3
        imagePullPolicy: Always
        name: installer
        command:
        ports:
        - containerPort: 22
        resources:
          requests:
            cpu: "50m"
            memory: "50Mi"
          limits:
            cpu: "250m"
            memory: "250Mi"
        env:
          - name: INSTALL_REPO
            value : "https://github.com/niklaushirt/awx-waiops.git"
```


## 2. Provide Entitlement

### 2.1. Get the CP4WAIOPS installation token

You can get the installation (pull) token from [https://myibm.ibm.com/products-services/containerlibrary](https://myibm.ibm.com/products-services/containerlibrary).

This allows the CP4WAIOPS images to be pulled from the IBM Container Registry.

<div style="page-break-after: always;"></div>


### 2.2. Enter the CP4WAIOPS installation token

1. Open the AWX instance
2. Select `Inventories`
3. Select `CP4WAIOPS Install`
	![K8s CNI](./doc/pics/entitlement1.png)
4. Click Edit
5. Replace and uncomment the `ENTITLED_REGISTRY_KEY` 
	![K8s CNI](./doc/pics/entitlement2.png)
6. Click Save


Yop are now ready to lauch the installations.


## 3. Installing Components

The following Components can be installed:


| Category| Component  | Description  | Remarks  | 
|---|---|---|---|
| **CP4WAIOPS Base Install** |  |  |  |
|| **10_InstallCP4WAIOPSAIManagerwithDemoContent** | Base AI Manager with RobotShop and LDAP integration |  |
|| **11_InstallCP4WAIOPSAIEventManager** | Base Event Manager  |  |
|| | |  |
| **CP4WAIOPS Addons Install** |  | |  |
|| 17_InstallCP4WAIOPSToolbox | Debugging Toolbox |  |
|| 18_InstallCP4WAIOPSDemoUI | Demo UI to simulate incidents |  |
|| | |  |
| **Third-party** | | |  |
|| 14_InstallRookCeph | |  |
|| 20_InstallTurbonomic | |  |
|| 21_InstallHumio | |  |
|| 22_InstallAWX | |  |
|| 22_InstallELK | |  |
|| 24_InstallManageIQ | |  |
|| 29_InstallServiceMesh | |  |
|| | |  |
| **Training** |  | |  |
|| 85_TrainingCreate | Create all training definitions (LAD, TemporalGrouping, Similar Incidents, Change Risk) |  |
|| 86_TrainingLoadLog | Not working yet, please use `./tools/02_training/robotshop-load-logs-for-training.sh` | 💣 |
|| 86_TrainingLoadSNOW | Not working yet, please use `./tools/02_training/robotshop-load-snow-for-training.sh` | 💣 |
|| 87_TrainingRunLog | Run the LAD Training once the Indexes are loaded |  |
|| 87_TrainingRunSNOW | Run the Similar Incidents and Change Risk Training once the Indexes are loaded |  |
|| | |  |
| **Tools** | **Tools** | |  |
|| 91_DebugPatch | Repatch some errors (non destructive) |  |
|| 99_GetCP4WAIOPSLogins | Get Logins for all Components |  |
|| optional\_15_InstallLDAP | Already installed by the AI Manager Install |  |
|| optional\_16_InstallRobotShop | Already installed by the AI Manager Install |  |



# Login Information

You can find the AWX login information in the cp4waiops-installer Pod Logs.

Or run:

```bash
./tools/20_get_logins.sh
```


# Tool Pod Access

```bash
oc exec -it $(oc get po -n default|grep cp4waiops-tools|awk '{print$1}') -n default -- /bin/bash
```