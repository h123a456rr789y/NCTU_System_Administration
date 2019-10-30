#!/bin/sh
ls -RAl |
sort -k 5 -r -n |
awk 'BEGIN{ count=0; dirnum = 0; filenum = 0; totalsize =0; } 
/^-/{ if (count++ < 5) print count,":",$5 ,$9 } 
/^d/{dirnum++ } 
/^-/{filenum++;totalsize += $5;} 
END{ print "Dir num:"dirnum"\n" "File num:"filenum"\n" "Total : " totalsize }'
