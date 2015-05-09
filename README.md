# xbred : Handy mapreduce in bash.

```xbred``` is a wrapper tool which connects multiple mapreduce tasks written in ```bred```.

## About xbred
```xbred``` uses ```bred```, which enhances Erik Frey's
[```br```](https://github.com/erikfrey/bashreduce) for mapreduce task execution.
The detail is discussed [here](docs/BRED.md)

It's pronounced 'cross-bred' to express it is not an X application.

# Installation

1. Install ```bred``` (see [bred's documentation](docs/BRED.md). Don't worry. It's very easy.
2. Place ```xbred``` somewhere on your path. ```/usr/local/bin``` is recommended.

# Examples
```wordcount``` example written in ```xbred``` as follows.
The source of this example is found [here](examples/wordcount)

```main.xbred```
```sh

    #!/usr/local/bin/xbred

    #Id    Type Sinks  Key Interpreter Task
    Map1   M    Map2   1   sh;-c       inline:'xargs cat'
    Map2   M    Reduce 1   awk         file:map.awk
    Reduce R    -      1   awk         file:reduce.awk
```

Id is an Alphanumeric string which identifies each task.
Type defines task type of the task ```M``` for a map, ```R``` for a reduce.
Sinks are the destination tasks the output of the task goes to. You can specify mutiple sinks by joining them with ';'.
Key specifies the field by which ```bred``` partitions data.
Interpreter is a program by which your task will be run. If you want to run your task with ```sh -c```, you
can use a semicolon instead of a white space as shown above. 
Task defines what you want ```xbred``` to execute. If it starts with ```inline:```, the following string will be
the task. If it starts with ```file:```, the content of the file specified by the following string will be
executed as a task.

This is the main file which describes the entire word count job.
```Map1``` reads file names from stdin and prints their contents using ```xargs``` and ```cat```.
This process is distributed

```map.awk```
```bash

    {
        gsub(/([[:punct:]]|[[:blank:]])+/, " ", $0);
        n=split($0,cols," ");
        for (i = 1; i <= n; i++) { print cols[i]; };
    }
```

Printed contents are then read by ```Map2```.
This task splits each line in to words and prints them.

```reduce.awk```

```bash

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
```

Printed words are finally processed by ```Reduce``` task.
This task counts how many times the same word are repeated consecutively and print the word
and the number at last.

see [here](/examples) for more exmples

# Author
* Hiroshi Ukai <dakusui@gmail.com>

# See also
* https://github.com/erikfrey/bashreduce


