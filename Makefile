DIST ?= "trusty"
CWD=$(PWD)
TIMESTAMP ?= master
PACKAGE_VERSION=2.1.1~$(TIMESTAMP)
DPDK_PATH="contrail-dpdk-kernel-modules-dkms-2.1.1/contrail-dpdk-kernel-modules-2.1.1/dpdk-2.1.1"
DPDK_BRANCH ?= contrail_dpdk_2_1
BUILD_AREA="build-area"

all: checkout build-source build-binary

checkout:
	rm -rf $(DPDK_PATH) || true
	git clone -b $(DPDK_BRANCH) https://github.com/Mirantis/contrail-dpdk.git $(DPDK_PATH)

build-source:
	docker run -t -v $(CWD):$(CWD) -w $(CWD) --rm=true tcpcloud/debian-build-ubuntu-$(DIST) /bin/bash -c " \
		(rm -rf $(BUILD_AREA) || true) && \
		mkdir -p $(BUILD_AREA)/packages/ && \
		cp -R contrail-dpdk-kernel-modules-dkms-2.1.1/ $(BUILD_AREA)/packages/ && \
		sed -i 's/VERSION/$(PACKAGE_VERSION)/g' $(BUILD_AREA)/packages/contrail-dpdk-kernel-modules-dkms-2.1.1/debian/changelog && \
		(cd $(BUILD_AREA)/packages/contrail-dpdk-kernel-modules-dkms-2.1.1; dpkg-buildpackage -S -us -uc -d) "
       

build-binary:
	docker run -t -v $(CWD):$(CWD) -w $(CWD) --rm=true tcpcloud/debian-build-ubuntu-$(DIST) /bin/bash -c "sudo apt-get update; sudo apt-get install -y devscripts; \
		dpkg-source -x $(BUILD_AREA)/packages/contrail-dpdk-kernel-modules-dkms_*.dsc $(BUILD_AREA)/contrail-dpdk-kernel-modules-dkms; \
		cd $(BUILD_AREA)/contrail-dpdk-kernel-modules-dkms; dpkg-checkbuilddeps 2>&1|rev|cut -d : -f 1|rev|sed 's,([^)]*),,g'|xargs sudo apt-get install -y; \
		debuild --no-lintian -uc -us"
