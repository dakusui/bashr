# ```bredxbred```: ```bred``` and ```xbred```

```bredxbred``` is a project to develop an easy map reduce framework where you can define map and reduce jobs with your daily tools like bash, awk, perl, etc.

It consists of two components,
* ```bred```: Enhanced version of 'bashreduce'. Original bashreduce was developed by Erik Frey. It enables you to write a map reduce job. 
* ```xbred```: an interpreter to write a pipeline which consists of ```bred``` based map reduce jobs.


# Requirements

## Platform
```bred``` and ```xbred`` are on following platforms.

* Raspbian GNU/Linux 7
* Ubuntu 14.04.2 LTS

## Software dependencies

* bash (Ubuntu - 4.3.11(1), Raspbian - 4.2.37(1))
* Other Unix tools
 * coreutils 
 * netcat-traditional (nc command. It must support listen mode)
 * pv
 * gawk
 * openssh-client
 * openssh-server
 * rsync

# Installation
## Build a utility program: ```brp```
Build a utility program ```brp``` by running make command in ```utils``` directory.

```bash

    $ cd utils
	$ make
	
```


## Place files somewhere handy in your PATH
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

Following is the content of ```bred.conf```.
Basically you can use it without modifying it.

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
* ```hosts```: If you have more than 4 cores, By repeating ```localhost``` as many as the number of your cores, you might be able to exploit the CPU's power.
* ```namenode```:  The host name of this machine. This name must be able to be accessed through passwordless ssh from all the hosts listed in ```hosts```.

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

Refer to [XBRED](docs/XBRED.md) for more details.
You can find more examples under [examples](examples/EXAMPLES.md) directory.

# Future works
* Create an installer.
* Rectify terminology in script files. "task" and "job" are used in inconsistent ways.

# Author
* Erik Frey <erik@fawx.com>
* Hiroshi Ukai <dakusui@gmail.com>

# See also
* [BRED](docs/BRED.md)
* [XBRED](docs/XBRED.md)
* [bashreduce](https://github.com/erikfrey/bashreduce)
