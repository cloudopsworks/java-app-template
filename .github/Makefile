##
# (c) 2022 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
OS := $(shell uname)
PWD := $(shell pwd)
CURR := $(shell basename $(PWD))
DATE :=	$(shell date +%Y%m%d-%H%M%S.%s)
VER_NUM := $(shell cat _VERSION)
VER_MAJOR := $(shell echo $(VER_NUM) | cut -f1 -d.)
VER_MINOR := $(shell echo $(VER_NUM) | cut -f2 -d.)
VER_PATCH := $(shell echo $(VER_NUM) | cut -f3 -d.)

.PHONY: tag

tag:
	git tag -f $(VER_MAJOR).$(VER_MINOR)
	git tag -f $(VER_MAJOR)

