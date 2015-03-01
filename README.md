# bred : bashreduce enhanced.

```bred``` is an enhanced version of erikfrey's ```bashreduce```

## About [```bashreduce```](https://github.com/erikfrey/bashreduce)
```bashreduce``` is a shell script created by erikfrey that lets you apply your favorite unix tools in a mapreduce fashion
across multiple machines/cores.  There's no installation, administration, or distributed filesystem.

## About ```bred```
```bred``` is an enhanced version of ```bashreduce```.
Same as ```bashreduce```, you'll only need:

* "bred":http://github.com/dakusui/bred/blob/master/bred somewhere handy in your path
* vanilla unix tools: sort, awk, ssh, netcat, pv
* password-less ssh to each machine you plan to use

Below are the enhancements implemented in ```bred```

* Created 'map' and 'reduce' behaviour modes, which allow you to perform
  tasks more normal mapreduce way. The behavior erikfrey created is now
  called 'compat' and it is still a default.
* Made it possible to specify job_id (-j option) by an integer. Based on this
  number bred allocates ports to be used and now you can use bred multiple
  times in a command line connecting them pipes.
* Made it possible to specify base port.
* Added 'sort_opt' option to be able to make sort commands use it. This is
  useful e.g., when you want to sort the output by a numeric field. Use "-s '-n'"
* User code's stderrs are now output to files. Now debugging became much easier.
* Bundled ```br-test.sh```. By running this, you can check your machine is capable of
  running ```bred``` or ```bashreduce```
* Reorganized internal structure.

But one more difference from ```bashreduce``` is

* ```bred``` doesn't have ```brm```: I gave up making it consistent with 'sort -m'.

# Configuration

## br.hosts file
Edit ```~/.br.hosts``` and/or ```/etc/br.hosts``` and enter the machines you wish to use as workers.
Or specify your machines at runtime:

```
bred -m "host1 host2 host3"
```
To take advantage of multiple cores, repeat the host name.

Below is my configuration, :)

```

localhost
localhost
localhost
localhost
localhost
localhost
localhost
localhost
```

## ```brp```

In order to improve performance, you can use a helper program ```brp```.
To compile it, type ```make``` in ```brutils``` directory.
And copy ```brp``` to a directory on your path. Probably the same directory as
```bred```'s would be handy.

Please refer to 'Notes' section to know potential problems usage of this utility can cause.

# Examples
## Distributed indexing

You can perform distributed indexing by one-liner with ```bred```.
Suppose you have only several ```localhost```'s and you'll run

```bash
find $(pwd) -type f -name '*.md' |nl -w 1 -s ' ' -b a|tee docid.txt |pv |bred -c 1 -s 3 -S1G -M map -j 0 -I 'awk' -r '{
  for (l=1; (getline line < $2) > 0; l++) {
     gsub(/([[:punct:]]|[[:blank:]])+/, " ", line);
     n=split(line,cols," ");
     for (i = 2; i < n; i++) { print $1, l, cols[i]; };
  }
}' |tee terms.txt |pv |bred -c 3 -s 1 -O no -M reduce -j 1 -S1G -I 'awk' -r 'BEGIN { p=""; key="";} {
    if (key == "") key=$3;
    p=p " " $1 "," $2
} END { print "" key " " p; }' -o index.txt
```

* NOTE) trying ```find . -type f -name ...``` will generate no output. Because awk doesn't read a file name like
  from ```./hello.txt``` since it doesn't expand '.' or '~' to their full-path representations.

This indexes all the '*.md' files under current directly.
A document id file and an inverted index will be generated as ```docid.txt``` and ```index.txt``` and they will look like below

* docid.txt
```

     6  /home/dakusui/workspace/symfonion/src/test/java/com/github/dakusui/symfonion/InvalidJsonErrorTest.java
     7  /home/dakusui/workspace/symfonion/src/test/java/com/github/dakusui/symfonion/core/FractionTest.java
     8  /home/dakusui/workspace/symfonion/src/test/java/com/github/dakusui/symfonion/InvalidDataErrorTest.java
     9  /home/dakusui/workspace/symfonion/src/test/java/com/github/dakusui/symfonion/ErrorTest.java
```

The first column of ```docid.txt``` is ID of each document and the second is the file's absolute location.

* index.txt
```

    planes  18,166 18,248 18,303 23,269 23,293
    SpritePlane  18,134 18,299 18,305 18,306 24,34 29,15 29,18
    QuitMu64  18,350 18,354 18,368 18,373
    setProperty  18,379 18,380 18,381 18,382
    Auto  16,156 16,169 19,134 25,52 25,55 25,58 25,61 25,64 25,67 25,70 41,111
    generated  16,156 16,169 19,134 25,52 25,55 25,58 25,61 25,64 25,67 25,70 41,111
    enabled  19,16 19,47 19,51
    VideoEngine  20,22 20,24 20,25 48,12 48,19 48,26
```

The words in the first column are indexed terms. The rest are positions where the term is found in the traversed document set.
Each element in a line is a comma separated string whose left part is document id, defined in ```docid.txt``` and the right side
is the line number where the term was found in the file.

If you prefer a script file, you can find it [here](examples/indexer.sh).

### Making it faster

The user code script you provide is executed by ```bred``` every time it finds a new key during reduce operation.
And the user code is executed as external command using the interpreter you specify by '-I' option.
If there are a lot of keys to be passed to the reduce function, command execution overhead damages the performance severely.

```bred``` provides another behavior mode called ```awk-native```. You can set this string to '-I' option and awk code string
which defines three functions: ```bredBeginReduce(key_idx)```, ```bredReduceReduce(key_idx)```, and ``````bredEndReduce()```.
When ```bred``` finds a new key, it first calls ```bredEndReduce``` for the previous key and the it calls ```bredBeginReduce```
for the new key. And for each line ```bredBeginReduce``` will be called.

A short experiment shows that there would be 3 times performance gain when I indexed all texts Project Gutenberg as of 2003 (400MB).

The example is found [here](examples/indexer2.sh).

Signatures of those 'hook' functions called by ```bred``` are floating right now. You might need to calibrate them to
make it work in future when you start using one of future versions of ```bred```.


## poor man's DFS
You can use ```bred``` as 'poor man's DFS'. Since I have implemented a small enhancement, you can specify a certain host
multiple times in br.hosts file.

### Creating a directory
Creating a directory is like this.
```
echo "" | ./bred -r 'mkdir -p /tmp/bredfs/${BRED_WORKER_IDX}/work' -T '-n' -c 1
```

```/tmp/bredfs``` is the directory in which you want to store your data. And this path can be anything as long as it is
available on all the hosts.

The string ```${BRED_WORKER_IDX}``` is the trick. This portion will be expanded differently on runtime depending on which
ssh processes, not on which hosts, so you do not break your data even if you specify a certain host name multiple times.

The portion ```/work``` is the path in the file system of poor man's DFS.
Maybe you want to define aliases to make it easy to use. Similarly,

### Writing a file
```
nl -w 1 -b a ~/Documents/FSM.md | bred -r 'cat > /tmp/bredfs/${BRED_WORKER_IDX}/work/FSM.md' -T '-n' -c 1 >& /dev/null
```
### Reading a file
```
echo "" | bred -r 'cat /tmp/bredfs/${BRED_WORKER_IDX}/work/FSM.md' -T '-n' -c 1 2> /dev/null | cut -f2-
```

### Listing a directory
```
echo "" | ./bred -r 'ls /tmp/bredfs/${BRED_WORKER_IDX}/work |sort' -T '-n' -c 1 2> /dev/null | sort -m | uniq
```

## Classic examples
Below are the examples from original ```br```

### sorting

```
bred < input > output
```

### word count

```
bred -r "uniq -c" < input > output
```

### great big join

```
LC_ALL='C' bred -r "join - /tmp/join_data" < input > output
```

# Performance
## map mode and reduce more
(not yet done)
Since I'm planning 2 major improvements which impact ```map``` and ```reduce``` modes, I have not yet started
performance testing.

## compatibility mode
This section is a work done by erikfrey and cited from [bashreduce's README](https://github.com/erikfrey/bashreduce/blob/master/README.textile).

### big honkin' local machine

Let's start with a simpler scenario: I have a machine with multiple cores and with normal unix tools I'm relegated to using just one core.  How does br help us here?  Here's br on an 8-core machine, essentially operating as a poor man's multi-core sort:


| command                                    | using     | time       | rate      |
|:-------------------------------------------|-----------|-----------:|----------:|
| sort -k1,1 -S2G 4gb_file > 4gb_file_sorted | coreutils | 30m32.078s | 2.24 MBps |
| br -i 4gb_file -o 4gb_file_sorted          | coreutils | 11m3.111s  | 6.18 MBps |
| br -i 4gb_file -o 4gb_file_sorted          | brp/brm   | 7m13.695s  | 9.44 MBps |


The job completely i/o saturates, but still a reasonable gain!

### many cheap machines

Here lies the promise of mapreduce: rather than use my big honkin' machine, I have a bunch of cheaper machines lying around that I can distribute my work to.  How does br behave when I add four cheaper 4-core machines into the mix?

|   command                                  |   using   |   time      |   rate     |
|:-------------------------------------------|-----------|------------:|-----------:|
| sort -k1,1 -S2G 4gb_file > 4gb_file_sorted | coreutils | 30m32.078s  |  2.24 MBps |
| br -i 4gb_file -o 4gb_file_sorted          | coreutils |  8m30.652s  |  8.02 MBps |
| br -i 4gb_file -o 4gb_file_sorted          | brp/brm   |  4m 7.596s  | 16.54 MBps |


We have a new bottleneck: we're limited by how quickly we can partition/pump our dataset out to the nodes.  awk and sort begin to show their limitations (our clever awk script is a bit cpu bound, and @sort -m@ can only merge so many files at once).  So we use two little helper programs written in C (yes, I know!  it's cheating!  if you can think of a better partition/merge using core unix tools, contact me) to partition the data and merge it back.

# Future work

* [Implement better data exchange mechanism #3](https://github.com/dakusui/bred/issues/3)
* [Execute awk function in a reduce task #6](https://github.com/dakusui/bred/issues/6)

# Notes
## About ```brp```'s behaviors
brp and the small awk script which dispatches rows basically do the same thing.
Both pick up a specified column, compute ```flvhash```, and dispatch the row to one of
output files.
But there are differences to be noticed.

1. ```brp``` detects column separator using ```isspace(3)```, which returns ```true```
   for " ". "\t", "\r", "\n", "\f", and "\v".
2. If ```brp``` finds  a character which makes ```isspace``` true, it immediately
   considers a field separator. Even if the row starts with those characters, or even
   if multiple white space characters are next to each other.

For example, perhaps the command line below is a bad practice.

```
    cat -n infile | br ...
```

Because ```cat -n``` produces results below,

```
___221	# Notes
___222	* About ```brp```'s behaviors
___223	brp and the small awk script which dispatches rows basically do the same thing.
___224	Both pick up a specified column, compute ```flvhash```, and dispatch the row to one of
```
(leading spaces are replaced with underlines)

Due to the ```brp```'s behavior described above, almost all the rows will be processed by the same worker since ```brp```
picks up a string of length 0 as the first field and compute a hash for it always.
Please use something like below instead.

```
    nl -w 1 -s ' ' -b a
```

# AUTHORS
* Erik Frey <erik@fawx.com>
* Daniel Alex Finkelstein
* Zhou Zheng Sheng <edwardbadboy@qq.com>
* Hiroshi Ukai <dakusui@gmail.com>

# SEE ALSO
* https://github.com/erikfrey/bashreduce
* https://github.com/danfinkelstein/bashreduce
* https://github.com/edwardbadboy
* https://github.com/dakusui/bred

# LICENSE
  The goodwill of Erik Frey.
