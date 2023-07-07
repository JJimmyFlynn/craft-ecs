#!/bin/sh

php ./craft up
php ./craft clear-caches/compiled-template && php ./craft clear-caches/data
