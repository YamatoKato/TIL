#!/bin/bash

# ディレクトリの作成
mkdir -p Blockchain/{Basics,SmartContracts,DApps,Platforms}
mkdir -p Backend/{API/{RESTful,GraphQL,gRPC},DesignPatterns,Databases/{SQL,NoSQL,NewSQL},Authentication_Authorization}
mkdir -p SRE/{Monitoring,IaC/{Terraform,Ansible},CI_CD/{Jenkins,GitHub_Actions,GitLab_CI},Containers/{Docker,Kubernetes}}
mkdir -p Infrastructure/{CloudProviders/{AWS,Azure,GCP},Virtualization}
mkdir -p Network/{Protocols,Security,Tools}

# .gitkeepファイルの作成
find TIL -type d -exec touch {}/.gitkeep \;
