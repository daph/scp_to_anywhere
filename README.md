# ScpToAnywhere

** MAJOR WORK IN PROGRESS **
** ANYTHING COULD CHANGE AT ANY TIME AND THE CODE IS SUPER RATTY AT THE MOMENT **

A project to create a server that you can just SCP stuff to and it'll end up where you want it.
Right now it only supports slack.

To use, make a directory called ssh with host keys in it, put your slack token in config, then start it up with `mix run --no-halt`.

Then you can scp like so: `scp -P8989 <file> localhost:<channel>`
ex: `scp -P8989 ~/myimportantfile localhost:tools`

![example2](https://user-images.githubusercontent.com/151402/30525373-582b3260-9bba-11e7-9f10-d5d5f65200d5.gif)

