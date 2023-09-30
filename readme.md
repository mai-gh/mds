# mds : markdown server


mds is a "bare bones" github flavored markdown http server with live reload. It uses redcarpet & rb-inotify. It only works for linux.


install the dependencies:

```
pacman -S ruby ruby-rb-inotify ruby-redcarpet
``` 


#### Usage:
1. `./mds.rb /path/to/readme.md`

2. Go to http://127.0.0.1:8000 in your browser.

3. Edit the readme.md file in your favorite editor.

