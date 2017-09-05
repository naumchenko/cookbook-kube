# Client

remote_file 'kubectl binary' do
  path '/usr/bin/kubectl'
  mode '0755'
  source 'https://storage.googleapis.com/kubernetes-release/release'\
         '/v1.2.4/bin/linux/amd64/kubectl'
  checksum 'dac61fbd506f7a17540feca691cd8a9d9d628d59661eebce788a50511f578897'
end

# Master

etcd_service 'default' do
  action %w(create start)
end # Needed by the kube_apiserver[default]

kube_apiserver 'default' do
  service_cluster_ip_range '10.0.0.1/24'
  etcd_servers 'http://127.0.0.1:4001'
  insecure_bind_address '0.0.0.0' # for convenience
  action %w(create start)
end

group 'docker' do
  members %w(kubernetes)
end

kube_scheduler 'default' do
  action %w(create start)
end

kube_controller_manager 'default' do
  action %w(create start)
end

# Node

apt_update

apt_repository 'docker' do
  uri 'https://apt.dockerproject.org/repo'
  distribution 'debian-jessie'
  components %w(main)
  keyserver 'p80.pool.sks-keyservers.net'
  key '58118E89F3A912897C070ADBF76221572C52609D'
  cache_rebuild true
end

directory '/etc/kubernetes/manifests' do
  recursive true
end

docker_service 'default' do
  iptables false
  ip_masq false
  storage_driver 'devicemapper'
  install_method 'package'
  version '1.9.1'
end # needed by kubelet_service[default]

kubelet_service 'default' do
  api_servers 'http://127.0.0.1:8080'
  pod_manifest_path '/etc/kubernetes/manifests'
  network_plugin 'kubenet'
  pod_cidr '10.180.1.0/24'
  cluster_dns '10.0.0.10'
  cluster_domain 'cluster.local'
  action %w(create start)
end

package 'ethtool' # needed by the kubelet

kube_proxy 'default' do
  action %w(create start)
end

# test running a sample pod

t = template '/etc/kubernetes/manifests/busybox.yaml'

execute 'kubectl create -f /etc/kubernetes/manifests/busybox.yaml' do
  action :nothing
  subscribes :run, "template[#{t.name}]", :immediately
end
