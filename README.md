# ```bredxbred```: ```bred``` and ```xbred```

```bredxbred``` is a project to develop an easy map reduce framework where you can define map and reduce jobs with your daily tools like bash, awk, perl, etc.

It consists of two components,

* ```bred```: Enhanced version of 'bashreduce'. Original bashreduce was developed by Erik Frey. It enables you to write a map reduce job.
* ```xbred```: an interpreter to write a pipeline which consists of ```bred``` based map reduce jobs.


# Requirements

## Platform
```bred``` and ```xbred``` are tested on following platforms.

* Ubuntu 16.04.2 LTS

## Software dependencies

 * bash (Ubuntu - 4.3.11(1), Raspbian - 4.2.37(1))
 * bash needs to be a login shell of the user who executes ```bred``` and ```xbred```
 * Other Unix tools
 * coreutils 
 * **netcat-traditional**
     * netcat-openbsd provides the nc command on many dristributions by default which is not good.
     * It also must support listen mode.
 * pv
 * gawk or any awk implementation provides ```awk```
     * mawk is considered faster than gawk in many cases
 * openssh-client
 * openssh-server
 * rsync


## Environment

* A unix user to execute ```bred``` and ```xbred```.
 * Currently only one user per environment can user ```bred``` and ```xbred```.
* Login shell
* Directories

# Installation
## Setting up an environment (on each machine)

* **Make sure all tests pass before the actual usage!**
* If something breaks down try cleaning up the environment first:
    * ```killall awk; killall nc; rm -rf [BRED_WORKDIR]/ && mkdir -p [BRED_WORKDIR]/{fs,jm,sort}```
* In case of problems try geing more information with ```export XBRED_DEBUG="on"```

## Build a utility program: ```brp```
Build a utility program ```brp``` by running make command in ```utils``` directory.

```bash

    $ cd utils
	$ make
	
```


## Place files somewhere handy in your PATH
**Should work with non-interactive shell usage as well, where .bashrc is not parsed!**
Recommended directory structure is shown below.
Make sure each of them has a correct permission (shown in parentheses)

```

    /usr/local
	    bin/
			bred.conf (644)
		        bred (744)
			bred-core (644)
			brp (755)
			xbred (755)

```

## Configure the environment

Following is the content of [```bred.conf```](bred.conf).
Basically you can use it without modifying it if you just want to exploit multi-core benefit of your local machine.

```

    baseport=10000
    hosts=(localhost localhost localhost localhost)
    namenode="${hosts[0]}"
    workdir="/tmp/bred"
    fsdir="${workdir}/fs"
    jmdir="${workdir}/jm"
    sorttmpdir="${workdir}/sort"
    sortmem["${namenode}"]="32M"
    defaultsortmem="256K"

```

* ```baseport```: ```bred``` allocates ports to each task.
* ```hosts```: If you have more than 4 cores, by repeating ```localhost``` as many as the number of your cores, you might be able to exploit the CPU's power.
* ```namenode```:  The host name of this machine. This name must be able to be accessed through passwordless ssh from all the hosts listed in ```hosts```.
* ```workdir```: Directory under which all bred logs, contents, and data are stored. You must guarantee that this directory exists, visible, and writeble for the user who executes ```bred``` and ```xbred```.
* ```fsdir```: ```bred``` provides a "poorman's" distributed file system feature (```bredfs```). This directory stores all the contents in the file system in a distributed manner.
* ```jmdir```: ```bred``` has a feature to choose available port numbers automatically. In ```bred```, a "job number" is assigned to a set of ports used by one ```bred``` process, and managed under this directory so that it doesn't collide with other proceess's.

## Create directories
Create ```fsdir``` and ```jmdir``` and make sure they are writable by the user by whom you are going to execute ```bred``` and ```xbred```.



## Write your own map reduce program

Following is a 'word count' example written in ```xbred``` style.

```

    #!/usr/local/bin/xbred
    
    ####
    #          Id: main
    #        Type: map
    # Interpreter: sh
    #         Key: 1
    #       Sinks: wordcount
    function map map(awk -f,1,wordcount) inline:<<EOF
      {
        gsub(/([[:punct:]]|[[:blank:]])+/, " ", $0);
        n=split($0,cols," ");
        for (i = 1; i <= n; i++) { print cols[i]; };
      }
    EOF
    
    ####
    #          Id: wordcount
    #        Type: reduce
    # Interpreter: awk -f
    #         Key: 1
    #       Sinks: -
    function reduce wordcount(awk -f,1,-) inline:<<EOF
      BEGIN {
        c=0;
      }
      {
        if (key == "") key=$1;
        c++;
      }
      END {
        print "" key " " c;
      }
    EOF

```
**Run it with:** ```cat input.txt | ./word_count.xbred > output.txt```

Refer to [XBRED](docs/XBRED.md) for more details.
You can find more examples under [examples](examples/README.md) directory.

# Future works
* [Support Raspbian (xbred)](https://github.com/dakusui/bredxbred/issues/12)
* [Improve error handlings](https://github.com/dakusui/bredxbred/issues/7)
* [Directory listing support](https://github.com/dakusui/bredxbred/issues/8)
* [Create an installer](https://github.com/dakusui/bredxbred/issues/9)
* [Rectify terminology in script files. "task" and "job" are used in inconsistent ways](https://github.com/dakusui/bredxbred/issues/10)
* [Implement better data exchange mechanism](https://github.com/dakusui/bred/issues/3)
* [Allow quotations in variable declaration section of .xbred file](https://github.com/dakusui/bredxbred/issues/11)

# Author
* Erik Frey <erik@fawx.com>
* Hiroshi Ukai <dakusui@gmail.com>

# See also
* [BRED](docs/BRED.md)
* [XBRED](docs/XBRED.md)
* [bashreduce](https://github.com/erikfrey/bashreduce)
