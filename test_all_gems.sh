#!/bin/bash

set -e

test_gem() {
    bundle update --all
    bundle exec rake test
    bundle exec rubocop -A
    echo "testgem in $PWD"
}

for dir in */; do
    echo "Directory: $dir"
    if [[ $dir == 'contrib/' || $dir == 'examples/' || $dir == 'rakelib/' ]]; then
        continue
    fi

    if [[ $dir == 'exporter/' || $dir == 'propagator/' ]]; then
        cd $dir
        for subdir in */; do

            if [[ $subdir == 'jaeger/' ]]; then
                continue
            fi

            echo "Directory: $subdir"

            cd $subdir
            test_gem
            cd /app/$dir
        done
        cd /app
        continue
    fi

    cd $dir
    test_gem
    cd -
    # Add your logic here, e.g., check if it's a Ruby gem library
done
