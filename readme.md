# mds : markdown server


mds is a "bare bones" github flavored markdown http server with live reload. It uses 
[redcarpet](https://github.com/vmg/redcarpet), 
[rb-inotify](https://github.com/guard/rb-inotify), and
[github-markdown-css](https://github.com/sindresorhus/github-markdown-css). It only works for linux.


install the dependencies:

```
pacman -S ruby ruby-rb-inotify ruby-redcarpet
``` 


#### Usage:
1. `./mds.rb /path/to/readme.md`

2. `surf http://127.0.0.1:8000`

3. `vim /path/to/readme.md`

