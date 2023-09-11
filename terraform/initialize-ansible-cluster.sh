# PUBLIC IP
master_ansible_public_ip="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=master-ansible" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
control_plane_1_public_ip="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=control-plane-1" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
data_plane_1_public_ip="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=data-plane-1" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
data_plane_2_public_ip="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=data-plane-2" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"
data_plane_3_public_ip="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=data-plane-3" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)"

user=ubuntu

ssh-keygen -f "~/.ssh/known_hosts" -R $master_ansible_public_ip &
ssh-keygen -f "~/.ssh/known_hosts" -R $control_plane_1_public_ip &
ssh-keygen -f "~/.ssh/known_hosts" -R $data_plane_1_public_ip &
ssh-keygen -f "~/.ssh/known_hosts" -R $data_plane_2_public_ip &
ssh-keygen -f "~/.ssh/known_hosts" -R $data_plane_3_public_ip &

wait

ssh-keyscan -H $master_ansible_public_ip >> ~/.ssh/known_hosts &
ssh-keyscan -H $control_plane_1_public_ip >> ~/.ssh/known_hosts &
ssh-keyscan -H $data_plane_1_public_ip >> ~/.ssh/known_hosts &
ssh-keyscan -H $data_plane_2_public_ip >> ~/.ssh/known_hosts &
ssh-keyscan -H $data_plane_3_public_ip >> ~/.ssh/known_hosts &

wait

# Generer la paire de clé ssh du master ansible
ssh $user@$master_ansible_public_ip "echo -e 'y\n' | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"

# Recuperer la clé publique du master ansible
master_ansible_pub_key=$(ssh $user@$master_ansible_public_ip "cat ~/.ssh/id_rsa.pub")

echo
echo "Veuillez ajouter la clé du master ansible à votre compte github."
echo "Une fois la clé ajoutée cliquez sur ENTRER pour continuer."
echo
echo $master_ansible_pub_key
echo
echo "https://github.com/settings/ssh/new"
echo

read ENTRER

# Ajouter la clé publique du master ansible aux clés autorisées des nodes ansible
ssh $user@$control_plane_1_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &
ssh $user@$data_plane_1_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &
ssh $user@$data_plane_2_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &
ssh $user@$data_plane_3_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &

wait

# Ajouter les hostname des machines dans le master ansible
ssh $user@$master_ansible_public_ip 'sudo bash -c "echo \"10.240.0.5 control-plane-1\" >> /etc/hosts"' &
ssh $user@$master_ansible_public_ip 'sudo bash -c "echo \"10.240.0.6 data-plane-1\" >> /etc/hosts"' &
ssh $user@$master_ansible_public_ip 'sudo bash -c "echo \"10.240.0.7 data-plane-2\" >> /etc/hosts"' &
ssh $user@$master_ansible_public_ip 'sudo bash -c "echo \"10.240.0.8 data-plane-3\" >> /etc/hosts"' &

wait

# Ajouter les adresses ip des nodes ansibles aux hotes connues du master pour faciliter la connexion sans interruption
ssh $user@$master_ansible_public_ip "
ssh-keyscan -H control-plane-1 > ~/.ssh/known_hosts && \
ssh-keyscan -H data-plane-1 >> ~/.ssh/known_hosts && \
ssh-keyscan -H data-plane-2 >> ~/.ssh/known_hosts && \
ssh-keyscan -H data-plane-3 >> ~/.ssh/known_hosts
"

# Ajouter l'dresse de github.com pour faciliter la connexion sans interruption
ssh $user@$master_ansible_public_ip "ssh-keyscan -H github.com >> ~/.ssh/known_hosts"

# # Cloner le depot rke2
ssh $user@$master_ansible_public_ip "
git clone git@github.com:data354/aws_k8s.git  && \
cp -rd aws_k8s/ansible ansible  && \
rm -rdf aws_k8s  && \
cd ansible  && \
ansible-playbook -i inventory.ini prerequises.playbook.yml  && \
ansible-playbook -i inventory.ini main.playbook.yml
"

echo "Connection to Master ansible ..."
ssh $user@$master_ansible_public_ip