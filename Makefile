
default: assets

clean:
	rm -rf out public

assets: clean
	coffee -c src && rsync -a src public --exclude *.coffee && mv public/src public/assets
