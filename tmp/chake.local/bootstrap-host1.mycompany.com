#!/bin/sh
set -eu
hostname="$1"

echo "$hostname" > /etc/hostname
hostname --file /etc/hostname

fqdn=$(hostname --fqdn || true)
if [ "$fqdn" != "$hostname" ]; then
  # if hostname is bar.example.com, we also want `bar` to be in /etc/hosts
  short_hostname=$(echo "$hostname" | cut -d . -f 1)
  if [ "$short_hostname" != "$hostname" ] && ! grep -q "\s${short_hostname}" /etc/hosts; then
    hostname="$hostname $short_hostname"
  fi
  printf "127.0.1.1\t%s\n" "$hostname" >> /etc/hosts
fi

# Stop cloud-init from resetting the hostname
if [ -f /etc/cloud/cloud.cfg ]; then
  sed -i -e '/^\s*-\s*\(set_hostname\|update_hostname\)/d' /etc/cloud/cloud.cfg
fi
if [ -f /etc/centos-release ] && grep -q 'CentOS Linux release 7' /etc/centos-release; then
  cat > /etc/yum.repos.d/chef.key <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

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
sA==
=H60S
-----END PGP PUBLIC KEY BLOCK-----
EOF
  cat > /etc/yum.repos.d/chef.repo <<EOF
[chef_stable]
name=chef_stable
baseurl=https://packagecloud.io/chef/stable/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=file:///etc/yum.repos.d/chef.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
  yum install -y chef rsync
  exit
fi
if [ -x /usr/bin/apt-get ]; then
  apt-get update
  export DEBIAN_FRONTEND=noninteractive
  apt-get -q -y install rsync chef
  update-rc.d chef-client disable
  service chef-client stop
  exit
fi
echo "---------------------"
echo "Unsupported platform:"
echo "---------------------"
echo
for file in /etc/os-release /etc/issue; do
  if [ -f $file ]; then
    cat $file
    break
  fi
done
exit 1
