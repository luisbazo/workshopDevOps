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



filename='users.txt'
n=1

i=10
passwords="Passwords: "

groupadd docker
#systemctl stop docker
#systemctl start docker

while read line; do
   #Generate random password for the user
   pass="$(dd if=/dev/urandom bs=1 count=8 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev)"
#   echo "${pass}"

   #create the user in the linux system and add it to the docker group
   adduser user$i 

   echo "$line   user$i:$pass"
   echo "user$i:$pass" | chpasswd
   usermod -a -G docker user$i
   usermod --add-subuids 200000-201000 --add-subgids 200000-201000 user$i
   
   passwords="$passwords user$i=$pass"   
   
   i=$(($i+1))
#  echo $i
done < $filename




filename='users.txt'
i=10
while read line; do
   #create the namespace
   echo "oc new-project ns$i"
   oc new-project ns$i
   #give rights to each user to its project 
   echo "   oc -n ns$i patch rolebinding admin --type='json' -p='[{"op": "replace", "path": "/subjects/0", "value":{"apiGroup": "rbac.authorization.k8s.io","kind": "User","name": "IAM#$line"}}]'  "
   oc -n ns$i patch rolebinding admin --type='json' -p='[{"op": "replace", "path": "/subjects/0", "value":{"apiGroup": "rbac.authorization.k8s.io","kind": "User","name": "IAM#$line"}}]'

   # needed to create an imagestream
   oc adm policy add-role-to-user admin IAM#$line -n ns$i

   # needed for network policy lab
   oc policy add-role-to-user edit IAM#$line -n ns-network

   enableClusterRole
   enableRoleBinding ns$i $line

   # needed to give root rights to docker images
   oc adm policy add-scc-to-user anyuid -z default -n ns$i
   
   # need cluste role self-provisioner to create project for ci cd
   oc adm policy add-cluster-role-to-user self-provisioner IAM#$line
 
   #copy some yaml files used during the labs to the new user home folder
   cp -r ./artifacts /home/user$i
   chown -R user$i:user$i /home/user$i/artifacts
   
   ls /home/user$i/artifacts/*.yaml | awk '{print $1}' | xargs sed -i "s/userX/user$i/g"
   ls /home/user$i/artifacts/*.yaml | awk '{print $1}' | xargs sed -i "s/nsX/ns$i/g"
   
   
   cp ./artifacts/javaee/HelloK8s.war /home/user$i
   chown user$i:user$i /home/user$i/HelloK8s.war
   
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
