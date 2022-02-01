#!/bin/sh


enableClusterRole()
{
  cat <<EOF | oc apply -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: aggregate-olm-edit2
  labels:
    rbac.authorization.k8s.io/aggregate-to-admin: 'true'
    rbac.authorization.k8s.io/aggregate-to-edit: 'true'
rules:
  - verbs:
      - create
      - update
      - patch
      - delete
    apiGroups:
      - operators.coreos.com
    resources:
      - subscriptions
      - operatorgroups
  - verbs:
      - delete
    apiGroups:
      - operators.coreos.com
    resources:
      - clusterserviceversions
      - catalogsources
      - installplans
      - subscriptions
EOF
}



enableRoleBinding() {
  cat <<EOF | oc apply -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: operators-edit2
  namespace: $1
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: IAM#$2
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aggregate-olm-edit2
EOF
}




filename='users1.txt'
i=106
while read line; do
   #create the namespace
   #give rights to each user to its project 
   echo "   oc -n ns$i patch rolebinding admin --type='json' -p='[{"op": "replace", "path": "/subjects/0", "value":{"apiGroup": "rbac.authorization.k8s.io","kind": "User","name": "IAM#$line"}}]'  "
   oc -n ns$i patch rolebinding admin --type='json' -p='[{"op": "replace", "path": "/subjects/0", "value":{"apiGroup": "rbac.authorization.k8s.io","kind": "User","name": "IAM#$line"}}]'

   # needed to create an imagestream
   oc adm policy add-role-to-user admin IAM#$line -n ns$i

   # needed for network policy lab
   oc policy add-role-to-user edit IAM#$line -n ns-network

   enableClusterRole
   enableRoleBinding ns$i $line

   # need cluste role self-provisioner to create project for ci cd
   oc adm policy add-cluster-role-to-user self-provisioner IAM#$line

   # needed to give root rights to docker images
   oc adm policy add-scc-to-user anyuid -z default -n ns$i
   
   for e in dev qa staging production; do
   # create a new namespace for each user and env
   # make user admin of the new project
      oc policy add-role-to-user admin IAM#${line} -n project${i}-${e}
   done

   #Add users to the admin groups of devtoolkit needed
   for group in ibm-toolkit-users argocd-admins; do
      oc adm groups add-users ${group} IAM#${line}
   done
    
   i=$(($i+1))
   echo $i
done < $filename
