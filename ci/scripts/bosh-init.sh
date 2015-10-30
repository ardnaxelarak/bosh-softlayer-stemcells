#!/bin/bash

set -e

pushd light-stemcell
    LIGHT_STEMCELL=`ls *.tgz`
    STEMCELL_PATH=$PWD/$LIGHT_STEMCELL
popd

pushd final-release
    CPI_RELEASE=$PWD/`ls *.tgz`
popd

pushd sl-bosh-release
    BOSH_RELEASE=$PWD/`ls *.tgz`
popd

mkdir bosh-init

director_uuid=$(bosh -n status --uuid)

deplopment=$PWD/bosh-init/bosh.yml

# Create deploment manifest
cat > $deployment << EOF
---
name: bosh

releases:
- name: bosh
  url: file://$BOSH_RELEASE
- name: bosh-softlayer-cpi
  url: file://$CPI_RELEASE

resource_pools:
- name: vms
  network: default
  stemcell:
    url: file://$STEMCELL_PATH
  cloud_properties:
    Domain: softlayer.com
    VmNamePrefix: bosh-experimental  # <--- It is better to use a catchy name which will be used in the following section
    StartCpus: 1
    MaxMemory: 1024
    Datacenter:
       Name: $SL_DATACENTER
    HourlyBillingFlag: true
disk_pools:
- name: disks
  disk_size: 40_000
  cloud_properties:
    consistent_performance_iscsi: true


networks:
- name: default
  type: dynamic
  dns: [8.8.8.8] # <--- Replace with your DNS
  preconfigured: true


jobs:
- name: bosh
  instances: 1

  templates:
  - {name: nats, release: bosh}
  - {name: redis, release: bosh}
  - {name: postgres, release: bosh}
  - {name: blobstore, release: bosh}
  - {name: director, release: bosh}
  - {name: health_monitor, release: bosh}
  - {name: cpi, release: bosh-softlayer-cpi}

  resource_pool: vms
  persistent_disk_pool: disks

  networks:
  - name: default

  properties:
    nats:
      address: 127.0.0.1
      user: nats
      password: nats-password

    redis:
      listen_addresss: 127.0.0.1
      address: 127.0.0.1
      password: redis-password

    postgres: &db
      host: 127.0.0.1
      user: postgres
      password: postgres-password
      database: bosh
      adapter: postgres

    blobstore:
      address: 127.0.0.1
      port: 25250
      provider: dav
      director: {user: director, password: director-password}
      agent: {user: agent, password: agent-password}

    director:
      address: 127.0.0.1
      name: my-bosh
      db: *db
      cpi_job: cpi
      max_threads: 3

    hm:
      director_account: {user: admin, password: admin}
      resurrector_enabled: true

    softlayer: &softlayer
      username: $SL_USERNAME
      apiKey: $SL_API_KEY
      public_vlan_id: fake-public-vlan   # <--- Replace with proper private vlan if needed
      private_vlan_id: fake-private-vlan # <--- Replace with proper private vlan if needed
      data_center: $SL_DATACENTER

    cpi:
      agent: {mbus: "nats://nats:nats-password@127.0.0.1:4222"}

    ntp: &ntp []

cloud_provider:
  template: {name: cpi, release: bosh-softlayer-cpi}
  mbus: "https://admin:admin@bosh-experimental.softlayer.com:6868" # <--- Replace with VmNamePrefix + Domain indicated in cloud_properties of resource_pools section, as bosh-init does not support dynamic ip, it is only supporting static/floating ip, so we are using predined hostname in mbus. Please don't use IP here.
  properties:
    softlayer: *softlayer
    cpi:
      agent:
        mbus: https://admin:admin@127.0.0.1:6868
        ntp: *ntp
        blobstore:
          provider: local
          options:
            blobstore_path: /var/vcap/micro_bosh/data/cache
EOF

cd bosh-init

echo "setting deploment..."
bosh-init deployment $deployment

bosh-init deploy $deployment
