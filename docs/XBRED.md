# xbred : Handy mapreduce in bash.

```xbred``` is a wrapper tool which connects multiple mapreduce jobs written in ```bred```.

## About xbred
```xbred``` uses ```bred```, which enhances Erik Frey's
[```bashreduce```](https://github.com/erikfrey/bashreduce), for mapreduce job execution.

It's pronounced 'cross-bred' to express it is not an X application.

# Writing an ```xbred``` program.

In this section, picking up a ```word count``` program bundled with ```xbred```, we'll discuss how you can write your own ```xbred``` program.
see [here](../examples/EXAMPLES.md) for more examples

Basically, an ```xbred``` program is a filter, but a way to make it non-filter one will be discussed in this section, too.
See "Shebang" sub-section.

## Write a "word count" example in ```xbred``` style.
"wordcount" example written in ```xbred``` as follows.
The source of this example is found [here](../examples/wordcount/)

```

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
    function {functype} {funcname}({interpreter},{keycolumn},{sinks}) file:{funcfile}
```

You can also let ```xbred``` read a file and define a function with the content of it.

### ```functype```: A type of a function
This component specifies a type of a function.
Possible types are ```map```, ```reduce```, and ```local```.

* ```map``` and ```reduce```: Those define map and reduce jobs respectively. The function will be distributed among hosts and executed.

* ```local```: This defines a local function, which will be executed on the same host as the enclosing file.

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
If you specify 2 for this component, the second column from the left of each line will be used to distribute data to be processed.

Column is recognized using white spaces.
Depending on a partitioning program you are using (built-in or ```brp```), behavior can be different.

If you don't install ```brp```, ```bred``` uses ```awk```, which considers consecutive white spaces as one separator, while ```brp``` considers them independent ones.
I would strongly recommend using ```brp``` always to avoid confusing behavior.


### ```sinks```: Other functions to which output of this function should be passed
Output of this function will be passed to functions specified here.
If the downstream function is a ```reduce```, a key converter job will be automatically generated and inserted.

If you specify a function name not defined in the same file, an error will be reported.
Note that ```xbred``` doesn't detect cyclic dependencies.

If you just want to print the output to stndard out, use ```-```


### function body
A function in ```.xbred``` file is a filter it reads input from ```stdin``` and writes output to ```stdout```.
E.g., the main function in the above example is translated into an ```awk``` filter program which is equivalent to

```

    awk '{
      gsub(/([[:punct:]]|[[:blank:]])+/, " ", $0);
      n=split($0,cols," ");
      for (i = 1; i <= n; i++) { print cols[i]; };
    }'

```

As mentioned already, there are two ways to define functions in ```xbred``` style.


#### ```keyword``` and ```funcbody```: A keyword to identify the end of this function
This component is an alphanumerical string (```[A-Za-z0-9_]+```) and specifies ```funcbody```.
The content in between the keywords will be extracted from the file, distributed to hosts defined in '.conf' file, and executed by ```bred```.

In the example above, the content in between two ```EOF```'s will be a body of the function ```map```.

```

    function map main(awk -f,1,wordcount) inline:<<EOF
    {
      gsub(/([[:punct:]]|[[:blank:]])+/, " ", $0);
      n=split($0,cols," ");
      for (i = 1; i <= n; i++) { print cols[i]; };
    }
    EOF

```


#### ```funcfile```: A function in a separate file.
If you want to define a function body outside your ```xbred``` file, you can use ```file:``` instead of ```inline:```.
```xbred``` will read the content of the file, distribute it to hosts defined in '.conf' file, and execute it.

E.g., if you have an ```awk``` script whose file name is ```/tmp/map.awk```, you can do following.

```

    function map main(awk -f,1,wordcount) file:/tmp/map.awk

```

## Variable declaration

Followings are declarations of variables in a ```.xbred``` file.

```

    declare SRCDIRS=/mnt/livius/Qmultimedia/FLAC:/mnt/livius/Qmultimedia/HIRES
    declare DESTDIR=/mnt/livius/Qmultimedia/PS3-test/Music

```

The declared variables are available in function bodies.
You can use them as usual environment variables as following.

```

    for srcdir in $(echo ${SRCDIRS} | sed -e 's/:/ /g')
    do
        find "${srcdir}" -type f -size +1c -not -name '.*' -exec printf "${srcdir} %s\n" {} \; | \

```

IMPORTANT: Note that ```xbred``` doesn't handle quotations with any special care.
If you do like this

```

    declare var="Hello world"

```

Quotations will be a part of the value. ```echo $var``` will print ```"Hello world"```, not ```Hello world```.


## Shebang
As already mentioned ```.xbred``` program is a filter, but sometimes you want to create a non-filter one.
If you don't need any input for your program, you can do


```bash

    #!/usr/local/bin/xbred -i /dev/null

```

Your program will read input from ```/dev/null```, which immediately reaches the end.
An example of this usage is found [here](examples/mconv/mconv.xbred)
    

# Executing a ```.xbred``` file.

You can simply give your program to ```xbred``` command as its argument.

```

    $ xbred yourprogram.xbred
   
```


# Future works
* Allow quotations in variable declarations.

# Author
* Hiroshi Ukai <dakusui@gmail.com>

# See also
* [README](../README.md)
* [bashreduce](https://github.com/erikfrey/bashreduce)


