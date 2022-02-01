FROM quay.io/openshift/origin-cli:latest


RUN curl -L https://github.com/IBM/cloud-pak-cli/releases/latest/download/cloudctl-linux-amd64.tar.gz -o cloudctl-linux-amd64.tar.gz
RUN tar xfvz cloudctl-linux-amd64.tar.gz
RUN mv cloudctl-linux-amd64 /usr/local/bin/cloudctl
RUN rm cloudctl-linux-amd64.tar.gz
RUN wget https://github.com/derailed/k9s/releases/download/v0.24.15/k9s_Linux_x86_64.tar.gz
RUN tar xfzv k9s_Linux_x86_64.tar.gz
RUN mv k9s /usr/local/bin
RUN rm LICENSE
RUN rm README.md
RUN yum install -y ansible
RUN ansible-galaxy collection install community.kubernetes:1.2.1
RUN apt-get install -y kafkacat
RUN apt-get install -y npm
RUN npm install elasticdump -g
RUN apt-get install -y jq
RUN curl -L https://github.com/IBM/cloud-pak-cli/releases/latest/download/cloudctl-linux-amd64.tar.gz -o cloudctl-linux-amd64.tar.gz
RUN tar xfvz cloudctl-linux-amd64.tar.gz
RUN sudo mv cloudctl-linux-amd64 /usr/local/bin/cloudctl
RUN rm cloudctl-linux-amd64.tar.gz
RUN curl -L https://github.com/argoproj/argo-cd/releases/download/v2.2.2/argocd-linux-amd64 -o argocd
RUN mv argocd /usr/local/bin/argocd


