# Used by COPR's make_srpm method: make -f .copr/Makefile srpm outdir=... spec=...
top := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

srpm:
	dnf -y install rpmdevtools kf6-rpm-macros
	spectool -g -C $(top) $(top)/powerdevil.spec
	rpmbuild -bs --define "_sourcedir $(top)" --define "_srcrpmdir $(outdir)" $(top)/powerdevil.spec
