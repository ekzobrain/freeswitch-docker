.PHONY: build push
build:
	docker build -t soulhunter1987/freeswitch-docker:1.8 .

push:
	docker login
	docker push soulhunter1987/freeswitch-docker:1.8
