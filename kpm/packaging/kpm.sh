#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`dirname \"$0\"`"
SELFDIR="`cd \"$SELFDIR\" && pwd`"

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$SELFDIR/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

# Run the actual app using the bundled Ruby interpreter, with Bundler activated.
# See https://github.com/phusion/traveling-ruby/issues/58
exec "$SELFDIR/lib/ruby/bin/ruby" -rbundler/setup -rreadline $SELFDIR/lib/vendor/*ruby/2.*/bin/kpm $@
