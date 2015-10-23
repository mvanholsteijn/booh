NAME=$(shell basename $(PWD))
IMAGE=mvanholsteijn/$(NAME)
VERSION=$(shell [ -z "$$(git status -s)" ] && cat .release || git describe --tag --long)
BRANCH=$(shell git branch  | sed -n -e 's/^\* //p')


build: 
	docker build --no-cache --force-rm -t $(IMAGE):$(VERSION) .
	docker tag  -f $(IMAGE):$(VERSION)
	@echo $(IMAGE):$(VERSION)

display:
	echo $(VERSION)

bump-patch: 
	VERSION=$(shell version=$$(<.release); \
		major=$$(echo $$version | cut -d. -f1,2); \
		patch=$$(echo $$version | cut -d. -f3);  \
		version=$$(printf "%s.%d" $$major $$(($$patch + 1))) ; echo $$version )

bump-minor:  
	VERSION=$(shell version=$$(<.release); \
		major=$$(echo $$version | cut -d. -f1); \
		minor=$$(echo $$version | cut -d. -f2); \
		version=$$(printf "%d.%d.0" $$major $$(($$minor + 1))) ; echo $$version )

bump-major:  
	VERSION=$(shell version=$$(<.release); \
		major=$$(echo $$version | cut -d. -f1); \
		version=$$(printf "%d.0.0" $$(($$major + 1))) ; echo $$version )

tag: check-status
	@[ -n "$(git tag | grep "^$(VERSION)\$$") ] || (echo "version already tagged in git" >&2 && exit 1) ; \
	echo $(VERSION) > .release ;  \
	git add .release ; \
	git commit -m "bumped to version $$version" ; \
	git tag $$version ; \
	git push origin $(BRANCH) --follow-tags 

check-status:
	@[ -z "$$(git status -s)" ] || (echo "outstanding changes" ; git status -s && exit 1)

release-patch: bump-patch tag release

release-minor: bump-minor tag release

release-major: bump-major tag release

check-release: 
	@[ -n "$(git diff --summary -r $(RELEASE)" ] || (echo "current directory differs from tagged $(<.release)" ; exit 1) 

release: check-status check-release build
	echo docker push $(IMAGE):$(VERSION)
	echo docker push $(IMAGE):$(VERSION)

