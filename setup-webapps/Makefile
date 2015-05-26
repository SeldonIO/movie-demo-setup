MOVIE_DEMO_FRONTEND_TAG=tags/v1.3.1

dummy:
	@echo dummy

swagger-codegen:
	git clone https://github.com/swagger-api/swagger-codegen
	cd swagger-codegen ; git checkout tags/2.0.17 ; npm install js-yaml

webapps/api-spec/seldon.json:swagger-codegen
	mkdir -p webapps/api-spec
	node swagger-codegen/bin/yml2swagger.js api-spec/seldon webapps/api-spec

webapps/swagger:
	mkdir -p webapps
	cp -R swagger/ webapps/swagger

webapps/movie-demo:
	git clone https://github.com/SeldonIO/movie-demo-frontend
	cd movie-demo-frontend ; git checkout $(MOVIE_DEMO_FRONTEND_TAG) ; npm install ; bower install ; cd ..
	cd movie-demo-frontend ; grunt build ; cd ..
	mkdir -p webapps/movie-demo
	cp -R movie-demo-frontend/dist/* webapps/movie-demo

webapps: webapps/swagger webapps/api-spec/seldon.json webapps/movie-demo

clean:
	@echo "removing swagger-codegen" && rm -rf swagger-codegen
	@echo "removing webapps/api-spec/seldon.json" && rm -rf webapps/api-spec/seldon.json
	@echo "removing webapps/swagger" && rm -rf webapps/swagger
	@echo "removing webapps/movie-demo" && rm -rf webapps/movie-demo
	@echo "removing movie-demo-frontend" && rm -rf movie-demo-frontend
	@echo "removing webapps" && rm -rf webapps

