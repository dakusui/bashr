# xbred : Handy mapreduce in bash.

```xbred``` is a wrapper tool which connects multiple mapreduce tasks written in ```bred```.

## About xbred
```xbred``` uses ```bred```, which enhances Erik Frey's
[```br```](https://github.com/erikfrey/bashreduce) for mapreduce task execution.
The detail is discussed [here](BRED.md)

It's pronounced 'cross-bred' to express it is not an X application.

# Writing an ```xbred``` program.
## Write a "word count" example in ```xbred``` style.
"wordcount" example written in ```xbred``` as follows.
The source of this example is found [here](examples/wordcount)

```bash

    #!/usr/local/bin/xbred
    
    ####
    #          Id: main
    #        Type: map
    # Interpreter: sh
    #         Key: 1
    #       Sinks: wordcount
    function map main(awk -f,1,wordcount) inline:<<EOF
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
    #           Sinks: -
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

As you see you can define functions, connect them, and build a pipeline.

## Variable declaration
(t.b.d.)

## Function declaration
A line which starts with ```#``` is considered a comment and ignored.
The line which starts with ```function``` is a declaration of a function.

Followings are formats to define functions.

* inline mode
```
    function {functype} {funcname}({interpreter},{keycolumn},{sinks}) inline:<<{keyword}
	  {funcbody}
	{keyword}
```

You can define a function with a ```funcbody``` within the same file.

* external file mode
```
    function {functype} {funcname}({interpreter},{keycolumn},{sinks}) file:{funfile}
```

You can also let ```xbred``` read a file and define a function with the content of it.

### ```functype```: A type of a function
This component specifies a type of a function.
Possible types are ```map```, ```reduce```, and ```local```.

* ```map``` and ```reduce```
Those define map and reduce jobs respectively. The function will be distributed among hosts and executed.

* ```local```
This defines a local function, which will be executed on the same host as the enclosing file.

### ```funcname```: A name of a function
This component gives a name to the function to be defined. The function name can be used in ```sinks``` component.

### ```interpreter```: An interpreter to execute a body of this function
This component chooses an interpreter to execute ```funcbody```.
In the above example ```awk -f``` is used for both ```main``` and ```wordcount``` functions.
As discussed later, ```xbred``` creates a temporary file from ```funcbody``` and execute it with the interpreter.
So you need to specify ```-f``` option to ```awk``` command.

As you see in the example, a comma is us used to split components inside parentheses after ```funcname```, you cannot include any comma in this component.

### ```keycolumn```: A column index
1-origin.
Specifies a column to map inputs or by which group inputs.

### ```sinks```: Other functions to which output of this function should be passed
### ```keyword```: A keyword to identify the end of this function
### ```funcbody```: A body of this function



The second token ```reduce``` is a type of the function. To declare a map
function, you can use ```map```. 

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
* [README](README.md)
* [BRED](BRED.md)
* https://github.com/erikfrey/bashreduce


