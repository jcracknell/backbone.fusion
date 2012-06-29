#!/bin/bash
COFFEE=coffee

rm -rf 'js/';

"$COFFEE" --compile --output js/ src/
rm -rf -- "-p" # Remove -p dir coffee creates on windows...

# Copy non-source files to output directory
find 'src/' | while read f; do
	if [ -f "$f" ]; then
		if [ ! "$(echo "$f" | grep '\.coffee$')" ]; then
			# Create directory if not exists
			dir="js$(dirname "$f" | sed -e 's/^src\(\/\|$\)/\1/')";
			if [ ! -d "$dir" ]; then
				mkdir -p "$dir";
			fi	

			of="$(echo "$f" | sed -e 's/src\/\(.*\)/js\/\1/')";
			echo "   copy: $f -> $of";
			cp "$f" "$of"
		fi
	fi
done	
