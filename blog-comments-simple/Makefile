
readme:
	cat pieces/opening.md > README.md
	sed -e 's/^/     /' base.html >> README.md
	cat pieces/middle1.md >> README.md
	sed -e 's/^/     /' good.html >> README.md

test: readme
	markdown README.md > index.html
	open index.html
