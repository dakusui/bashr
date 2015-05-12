# ```bredxbred```: ```bred```(bashreduce enhanced) and ```xbred```(cross bred)

```bredxbred``` is a project to develop an easy map reduce framework where you can define map and reduce jobs with your daily tools like bash, awk, perl, etc.

It consists of two components,
* ```bred```: 'bashreduce' (by Erik Frey) enhanced. Enables you to write a map reduce job. 
* ```xbred```: an interpreter to write a pipeline which consists of ```bred``` based map reduce jobs.

# Installation

## Build a utility program: ```brp```
Build a utility program ```brp``` by running make command in ```brutils``` directory.

```bash

    $ cd brutils
	$ make
	
```


## Place files somewhere on PATH
Recommended directory structure is shown below.

```

    /usr/local
	    bin/
			bred.conf
		    bred
			bred-core
			brp
			xbred

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

* baseport: ```bred``` allocates ports to each task.
* hosts: If you have more than 4 cores, By repeating ```localhost``` as many as the number of your cores, you might be able to exploit the CPU's power.

Refer to [BRED](BRED.md) for more details.

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

Refer to [XBRED](XBRED.md) for more details.
You can find more examples under [examples](examples/) directory.

# Future works
* Create an installer.
* Rectify terminology in script files. "task" and "job" are used in inconsistent ways.

# Author
* Erik Frey <erik@fawx.com>
* Hiroshi Ukai <dakusui@gmail.com>

# See also
* [BRED](BRED.md)
* [XBRED](XBRED.md)
* https://github.com/erikfrey/bashreduce

