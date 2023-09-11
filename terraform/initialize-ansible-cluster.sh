# PUBLIC IP
control_plane_1_public_ip="44.215.146.64"
data_plane_1_public_ip="54.235.21.79"
data_plane_2_public_ip="3.81.177.90"
data_plane_3_public_ip="35.169.88.61"
master_ansible_public_ip="52.22.31.97"

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
ssh ubuntu@$master_ansible_public_ip "echo -e 'y\n' | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"

# Recuperer la clé publique du master ansible
master_ansible_pub_key=$(ssh ubuntu@$master_ansible_public_ip "cat ~/.ssh/id_rsa.pub")

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
ssh ubuntu@$control_plane_1_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &
ssh ubuntu@$data_plane_1_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &
ssh ubuntu@$data_plane_2_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &
ssh ubuntu@$data_plane_3_public_ip "echo $master_ansible_pub_key > ~/.ssh/authorized_keys" &

wait

# Ajouter les adresses ip des nodes ansibles aux hotes connues du master pour faciliter la connexion sans interruption
ssh ubuntu@$master_ansible_public_ip "
ssh-keyscan -H control-plane-1 > ~/.ssh/known_hosts && \
ssh-keyscan -H data-plane-1 >> ~/.ssh/known_hosts && \
ssh-keyscan -H data-plane-2 >> ~/.ssh/known_hosts && \
ssh-keyscan -H data-plane-3 >> ~/.ssh/known_hosts
"

# Ajouter l'dresse de github.com pour faciliter la connexion sans interruption
ssh ubuntu@$master_ansible_public_ip "ssh-keyscan -H github.com >> ~/.ssh/known_hosts"

# # Cloner le depot rke2
ssh ubuntu@$master_ansible_public_ip "
git clone git@github.com:data354/gpt54.git && \
cp -rd gpt54/cluster/rke2 rke2 && \
rm -rdf gpt54"

echo "Master Ansible Public Ip : $master_ansible_public_ip"