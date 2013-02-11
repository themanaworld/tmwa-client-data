$ ~/Desktop ➜ mkdir client-data-test
$ ~/Desktop ➜ cd client-data-test
$ ~/Desktop/client-data-test ➜ git clone git://github.com/themanaworld/tmwa-client-data.git
Cloning into 'tmwa-client-data'...
remote: Counting objects: 15162, done.
remote: Compressing objects: 100% (5452/5452), done.
remote: Total 15162 (delta 9679), reused 15083 (delta 9629)
Receiving objects: 100% (15162/15162), 58.81 MiB | 188 KiB/s, done.
Resolving deltas: 100% (9679/9679), done.
$ ~/Desktop/client-data-test ➜ ls
tmwa-client-data
$ ~/Desktop/client-data-test ➜ cp -a tmwa-client-data/tools/client-updates .
$ ~/Desktop/client-data-test ➜ ls
client-updates  tmwa-client-data
$ ~/Desktop/client-data-test ➜ cd client-updates
$ ~/Desktop/client-data-test/client-updates ➜ ls
README  release  src
$ ~/Desktop/client-data-test/client-updates ➜ cd src
$ ~/Desktop/client-data-test/client-updates/src ➜ make
gcc -lz -o adler32 adler32.c
$ ~/Desktop/client-data-test/client-updates/src ➜ cp client-updates.conf.example client-updates.conf
$ ~/Desktop/client-data-test/client-updates/src ➜ vim client-updates.conf
$ ~/Desktop/client-data-test/client-updates/src ➜ cat client-updates.conf
# The client-data directory
CLIENT_DATA_DIR="$HOME/Desktop/client-data-test/tmwa-client-data"

# The updates working directory
UPDATES_DIR="$HOME/Desktop/client-data-test/client-updates"

# The git branch used for generating the updates
# This allows for more complex setups, where e.g a branch is used for merging
# from various other branches. It's used on the testing server
# Defaults to master
CLIENT_DATA_BRANCH=master

# Local directory served by the web server,
# where the update files will be copied
UPDATES_PUBLISH_DIR="$HOME/Desktop/client-data-test/www"
$ ~/Desktop/client-data-test/client-updates/src ➜ cd ..
$ ~/Desktop/client-data-test/client-updates ➜ git init
Initialized empty Git repository in /home/vincent/Desktop/client-data-test/client-updates/.git/
$ ~/Desktop/client-data-test/client-updates ➜ git add .
$ ~/Desktop/client-data-test/client-updates ➜ git commit -m 'Initial scripts'
[master (root-commit) 88b4d1f] Initial scripts
 12 files changed, 277 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 README
 create mode 100644 release/news.txt
 create mode 100644 release/resources.xml
 create mode 100644 release/resources2.txt
 create mode 100644 src/adler32.c
 create mode 100755 src/client-updates-gen
 create mode 100755 src/client-updates-inspect
 create mode 100755 src/client-updates-news
 create mode 100755 src/client-updates-push
 create mode 100644 src/client-updates.conf.example
 create mode 100644 src/makefile
$ ~/Desktop/client-data-test/client-updates ➜ cd ../tmwa-client-data
$ ~/Desktop/client-data-test/tmwa-client-data ➜ git log --oneline | tail -n 1
840c732 *** empty log message ***
$ ~/Desktop/client-data-test/tmwa-client-data ➜ cd ..
$ ~/Desktop/client-data-test ➜ mkdir www
$ ~/Desktop/client-data-test ➜ ls
client-updates  tmwa-client-data  www
$ ~/Desktop/client-data-test ➜ ./client-updates/src/client-updates-gen 840c732
Adding update-840c732..15ff3ba.zip:
Archive:  update-840c732..15ff3ba.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      191  02-06-2013 17:22   charcreation.xml
    18009  02-06-2013 17:22   COPYING
     1657  02-06-2013 17:22   ea-skills.xml
.................. MORE FILES HERE
........
........
---------                     -------
 20138266                     1793 files
$ ~/Desktop/client-data-test ➜ ls client-updates/release
news.txt  resources2.txt  resources.xml  update-840c732..15ff3ba.zip
$ ~/Desktop/client-data-test ➜ cat client-updates/release/{news.txt,resources2.txt,resources.xml}
update-840c732..15ff3ba.zip 71aa03f0
<?xml version="1.0"?>
<updates>
 <update type="data"  file="update-840c732..15ff3ba.zip" hash="71aa03f0" />
</updates>
$ ~/Desktop/client-data-test ➜ ./client-updates/src/client-updates-push
sending incremental file list
./
news.txt
resources.xml
resources2.txt
update-840c732..15ff3ba.zip

sent 16973826 bytes  received 91 bytes  33947834.00 bytes/sec
total size is 16971447  speedup is 1.00
$ ~/Desktop/client-data-test ➜ ls www
news.txt  resources2.txt  resources.xml  update-840c732..15ff3ba.zip
