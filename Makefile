SHELL=/bin/bash
SERVICES=culture-srv interieur-srv memoire-srv patriarcat-srv portail-srv
SHARED=proxy-srv

.PHONY: \
	clean stop start \
	$(SERVICES:-srv=) $(SERVICES:srv=stop) $(SERVICES:srv=start) $(SERVICES:srv=clean)

#
start: $(SERVICES:srv=start)
stop: $(SERVICES:srv=stop) $(SHARED:srv=stop)
clean: $(SERVICES:srv=clean) $(SHARED:srv=clean)
deploy: $(SERVICES:srv=deploy)
configure: $(SERVICES:srv=configure)

# proxy
proxy: proxy-start
proxy-start:
	docker-compose -f ${PWD}/srv/proxy/docker-compose.yml up -d
proxy-stop:
	docker-compose -f ${PWD}/srv/proxy/docker-compose.yml stop
proxy-clean: proxy-stop
	docker-compose -f ${PWD}/srv/proxy/docker-compose.yml rm -f

# service
$(SERVICES:-srv=): %: proxy %-start

# clean
$(SERVICES:srv=clean): %-clean: %-stop
	docker-compose -f ${PWD}/srv/$*/docker-compose.yml rm -f

# configure
$(SERVICES:srv=configure): %-configure:
	for f in `find ./srv/$*/ -name *.dist`; do \
		echo "$$f > `dirname $$f`/`basename $$f .dist`"; \
		source ./$$PROFILE.env; \
		if [ -f ./src/$*/$$PROFILE.env ]; then source ./src/$*/$$PROFILE.env; fi; \
		envsubst < $$f > `dirname $$f`/`basename $$f .dist`; \
	done

# deploy
$(SERVICES:srv=deploy): %-deploy: %-configure
	source ./$$PROFILE.env && \
	rsync -avz $$RSYNC_OPTIONS ./srv/$*/src/* -e "ssh -p 2222" gouuv@ftp.pastis-hosting.net:/var/www/vhosts/gouuv.fr/$*.gouuv.fr/

# start
$(SERVICES:srv=start): %-start: proxy
	docker-compose -f ${PWD}/srv/$*/docker-compose.yml up -d

# stop
$(SERVICES:srv=stop): %-stop:
	docker-compose -f ${PWD}/srv/$*/docker-compose.yml stop
