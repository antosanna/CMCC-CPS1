#!/bin/sh -l

#cnt=$(ps -u $USER|grep test|grep -v $$|wc -l)
cnt=$(ps -u $USER -f|grep test_ps.sh|grep -v $$|wc -l)
echo 'process running' $cnt
