
default: assets

clean:
	rm -rf out public && rm -rf src/js/*.js

assets: clean
	coffee -c src && rsync -a src public --exclude *.coffee && mv public/src public/assets

run:
	coffee -wc src
