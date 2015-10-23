NAME=$(shell basename $(PWD))
IMAGE=mvanholsteijn/$(NAME)
BRANCH=$(shell git branch  | sed -n -e 's/^\* //p')

VERSION=$(shell [ -z "$$(git status -s)" -a  -n "$$(git tag | grep '^$$(<.release)\$$')" -a  -z "$$(git diff --shortstat -r $$(<.release))" ] && cat .release ||  $$(git describe --tag --long))


build: 
	docker build --no-cache --force-rm -t $(IMAGE):$(VERSION) .
	docker tag  -f $(IMAGE):$(VERSION)
	@echo $(IMAGE):$(VERSION)

display:
	echo $(VERSION)

bump-patch: VERSION = $(shell version=$$(<.release); \
		major=$$(echo $$version | cut -d. -f1,2); \
		patch=$$(echo $$version | cut -d. -f3);  \
		version=$$(printf "%s.%d" $$major $$(($$patch + 1))) ; echo $$version )
bump-patch: tag
	echo $(VERSION)

bump-minor:  VERSION = $(shell version=$$(<.release); \
		major=$$(echo $$version | cut -d. -f1); \
		minor=$$(echo $$version | cut -d. -f2); \
		version=$$(printf "%d.%d.0" $$major $$(($$minor + 1))) ; echo $$version )
release-minor: tag
	echo $(VERSION)

release-major:  VERSION = $(shell version=$$(<.release); \
		major=$$(echo $$version | cut -d. -f1); \
		version=$$(printf "%d.0.0" $$(($$major + 1))) ; echo $$version )

release-major: tag
	echo $(VERSION)

tag: check-status
	echo in tag $(VERSION)
	[ -n $(shell git tag | grep "^$(VERSION)\$$") ] || (echo "version already tagged in git" >&2 && exit 1) ; 
	echo $(VERSION) > .release ;  
	git add .release ; 
	git commit -m "bumped to version $(VERSION)" ; 
	git tag $(VERSION) ;
	git push origin $(BRANCH) --follow-tags 

check-status:
	@[ -z "$$(git status -s)" ] || (echo "outstanding changes" ; git status -s && exit 1)


check-release: 
	@[ -n "$$(git tag | grep '^$$(<.release)\$$')" ] || (echo "$$(<.release) not yet tagged." ; exit 1) 
	@[ -n "$$(git diff --shortstat -r $$(<.release))" ] || (echo "current directory differs from tagged $$(<.release)" ; exit 1) 

release: check-status check-release build
	echo docker push $(IMAGE):$(VERSION)
	echo docker push $(IMAGE):$(VERSION)

