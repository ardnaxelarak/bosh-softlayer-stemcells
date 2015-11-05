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

dep_spec=$PWD/bosh-init/bosh.yml

# Create deploment manifest
cat > $dep_spec << EOF
---
name: bosh

releases:
- name: bosh
  url: file://$BOSH_RELEASE
- name: bosh-softlayer-cpi-release
  url: file://$CPI_RELEASE

resource_pools:
- name: vms
  network: default
  stemcell:
    url: file://$STEMCELL_PATH
  cloud_properties:
    Hostname: bosh-experimental
    Domain: softlayer.com
    StartCpus: 4
    MaxMemory: 8192
    Datacenter:
      Name: $SL_DATACENTER
    HourlyBillingFlag: true
    PrimaryNetworkComponent:
      NetworkVlan:
        Id: $SL_VLAN_PUBLIC
    PrimaryBackendNetworkComponent:
      NetworkVlan:
        Id: $SL_VLAN_PRIVATE
    NetworkComponents:
    - MaxSpeed: 1000

disk_pools:
- name: disks
  disk_size: 40_000
  cloud_properties:
    consistent_performance_iscsi: true

networks:
- name: default
  type: dynamic
  dns:
  - 8.8.8.8

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
  - {name: powerdns, release: bosh}
  - {name: cpi, release: bosh-softlayer-cpi-release}

  resource_pool: vms
  persistent_disk_pool: disks

  networks:
  - name: default

  properties:
    nats:
      user: nats
      password: nats
      auth_timeout: 3
      address: 127.0.0.1
      listen_address: 0.0.0.0
      port: 4222
      no_epoll: false
      no_kqueue: true
      ping_interval: 5
      ping_max_outstanding: 2
      http:
        port: 9222
    redis:
      address: 127.0.0.1
      password: redis
      port: 25255
      loglevel: info
    postgres: &20585760
      user: postgres
      password: postgres
      host: 127.0.0.1
      database: bosh
      adapter: postgres
    blobstore:
      address: 127.0.0.1
      director:
        user: director
        password: director
      agent:
        user: agent
        password: agent
      port: 25250
      provider: dav
    director:
      cpi_job: cpi
      address: 127.0.0.1
      name: bosh
      db:
        adapter: postgres
        database: bosh
        host: 127.0.0.1
        password: postgres
        user: postgres
    hm:
      http:
        user: hm
        password: hm
        port: 25923
      director_account:
        user: admin
        password: Cl0udyWeather
      intervals:
        log_stats: 300
        agent_timeout: 180
        rogue_agent_alert: 180
        prune_events: 30
        poll_director: 60
        poll_grace_period: 30
        analyze_agents: 60
      pagerduty_enabled: false
      resurrector_enabled: false
    dns:
      address: 127.0.0.1
      domain_name: microbosh
      db: *20585760
      webserver:
        port: 8081
        address: 0.0.0.0
    softlayer: &softlayer
      username: $SL_USERNAME
      apiKey: $SL_API_KEY
    cpi:
      agent:
        mbus: nats://nats:nats@127.0.0.1:4222
        ntp: []
        blobstore:
          provider: dav
          options:
            endpoint: http://127.0.0.1:25250
            user: agent
            password: agent
    ntp: &ntp []

cloud_provider:
  template: {name: cpi, release: bosh-softlayer-cpi-release}
  mbus: "https://admin:admin@bosh-experimental.softlayer.com:6868"

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

echo $PATH

cd bosh-init

echo "setting deploment..."
bosh-init deploy $dep_spec
