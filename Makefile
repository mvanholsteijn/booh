NAME=$(shell basename $(PWD))
IMAGE=mvanholsteijn/$(NAME)
BRANCH=$(shell git branch  | sed -n -e 's/^\* //p')

VERSION=$(shell . ../.make_support ; getVersion)

build: 
	docker build --no-cache --force-rm -t $(IMAGE):$(VERSION) .
	docker tag  -f $(IMAGE):$(VERSION)
	@echo $(IMAGE):$(VERSION)

release-patch: VERSION = $(shell . ../.make_support; nextPatchLevel)
release-patch: tag

release-minor: VERSION = $(shell . ../.make_support; nextMinorLevel)
release-minor: tag

release-major: VERSION = $(shell . ../.make_support; nextMajorLevel)
release-major: tag

tag: check-status
	. ../.make_support ; tagExists || (echo "ERROR: version $(VERSION) already tagged in git" >&2 && exit 1) ; 
	echo $(VERSION) > .release 
	git add .release 
	git commit -m "bumped to version $(VERSION)" ; 
	git tag $(VERSION) ;
	git push origin $(BRANCH) --follow-tags 

check-status:
	@. ../.make_support ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1) ; 

check-release: 
	. ../.make_support ; tagExists || (echo "ERROR: version not yet tagged in git" >&2 && exit 1) ; 
	. ../.make_support ; ! differsFromRelease || (echo "ERROR: current directory differs from tagged $$(<.release). make release-[minor,major,patch]." ; exit 1) 

release: check-status check-release build
	echo docker push $(IMAGE):$(VERSION)
	echo docker push $(IMAGE):$(VERSION)
