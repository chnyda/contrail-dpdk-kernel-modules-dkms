DIST="trusty"
CWD=$(PWD)
TIMESTAMP ?= master
PACKAGE_VERSION=2.1.2~$(TIMESTAMP)

all: checkout build-source build-binary

checkout:
	git clone git@github.com:Juniper/contrail-dpdk.git contrail-dpdk-kernel-modules-dkms-2.1.1/contrail-dpdk-kernel-modules-2.1.1/dpdk-2.1.1

build-source:
	TIMESTAMP=$(bash date -d @$(date +%s) +'%Y%m%d%H%M%S')

	(rm -rf build || true)
	mkdir -p build/packages/
	cp -R contrail-dpdk-kernel-modules-dkms-2.1.1/ build/packages/
	sed -i 's/VERSION/$(PACKAGE_VERSION)/g' build/packages/contrail-dpdk-kernel-modules-dkms-2.1.1/debian/changelog
	@echo "Building source package contrail-dpdk-kernel-modules-dkms-2.1.1"
	(cd build/packages/contrail-dpdk-kernel-modules-dkms-2.1.1; dpkg-buildpackage -S -us -uc)
       

build-binary:
	docker run -t -v $(CWD):$(CWD) -w $(CWD) --rm=true tcpcloud/debian-build-ubuntu-$(DIST) /bin/bash -c "sudo apt-get update; sudo apt-get install -y devscripts; \
		dpkg-source -x build/packages/contrail-dpdk-kernel-modules-dkms_*.dsc build/contrail-dpdk-kernel-modules-dkms; \
		cd build/contrail-dpdk-kernel-modules-dkms; dpkg-checkbuilddeps 2>&1|rev|cut -d : -f 1|rev|sed 's,([^)]*),,g'|xargs sudo apt-get install -y; \
		debuild --no-lintian -uc -us"
