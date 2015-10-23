NAME=$(shell basename $(PWD))
IMAGE=cargonauts/$(NAME)
BRANCH=$(shell git branch  | sed -n -e 's/^\* //p')

VERSION=$(shell . .make-release-support ; getVersion)

build: 
	echo docker build --no-cache --force-rm -t $(IMAGE):$(VERSION) .
	echo docker tag  -f $(IMAGE):$(VERSION)

release-patch: VERSION = $(shell . .make-release-support; nextPatchLevel)
release-patch: tag

release-minor: VERSION = $(shell . .make-release-support; nextMinorLevel)
release-minor: tag

release-major: VERSION = $(shell . .make-release-support; nextMajorLevel)
release-major: tag

tag: check-status
	@. .make-release-support ; tagExists || (echo "ERROR: version $(VERSION) already tagged in git" >&2 && exit 1) ; 
	@echo $(VERSION) > .release 
	git add .release 
	git commit -m "bumped to version $(VERSION)" ; 
	git tag $(VERSION) ;
	git push origin $(BRANCH) --follow-tags 

check-status:
	@. .make-release-support ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1) ; 

check-release: 
	@. .make-release-support ; tagExists || (echo "ERROR: version not yet tagged in git" >&2 && exit 1) ; 
	@. .make-release-support ; ! differsFromRelease || (echo "ERROR: current directory differs from tagged $$(<.release). make release-[minor,major,patch]." ; exit 1) 

release: check-status check-release build
	echo docker push $(IMAGE):$(VERSION)
	echo docker push $(IMAGE):$(VERSION)
