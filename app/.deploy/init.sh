#!/bin/sh

php ./craft up
php ./craft clear-caches/compiled-templates && php ./craft clear-caches/data
