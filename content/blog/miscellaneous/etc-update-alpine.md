---
title: "etc-update script for alpine linux"
linkTitle: "etc-update script for alpine linux"
date: 2019-04-02
description: >
  etc-update script for alpine linux
---

Alpine linux doesn't seem to have a tool to merge pending configuration changes, so I wrote one : 
{{< highlight sh >}}
#!/bin/sh
set -eu
 
for new_file in $(find /etc -iname '*.apk-new'); do
    current_file=${new_file%.apk-new}
    echo "===== New config file version for $current_file ====="
    diff ${current_file} ${new_file} || true
    while true; do
        echo "===== (r)eplace file with update?  (d)iscard update?  (m)erge files?  (i)gnore ====="
        PS2="k/d/m/i? "
        read choice
        case ${choice} in
            r)
                mv ${new_file} ${current_file}
                break;;
            d)
                rm -f ${new_file}
                break;;
            m)
                vimdiff ${new_file} ${current_file}
                break;;
            i)
                break;;
        esac
    done
done
{{< /highlight >}}

