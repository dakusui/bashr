## Job definition format

|Name |Type  	 |Key  |Key type|Source|Sinks           |Interpreter    |Task                |
|:----|:------:|----:|:-------|------|:---------------|:--------------|:-------------------|
|{str}|Map   	 |{num}|     num|{Name}|{Name};{Name}...|sh;-c          |{shell cmd}         |
|     |Reduce  |     | 	   str|      |                |awk            |{awk script}        |
|     |(Compat)|     | 	      |      |                |awk-native     |{awk scriptlet}     |
|     |Setup   |     | 	      |      |                |perl...        |{perl one-liner}... |



## New behaviour	modes
```
bred -M session-start  -f {jobdeffile} [-N {session}]
bred -M session-stop   -N {session}
bred -M session-status -N {session}
bred -M session-abort  -N {session}
bred -M session-list   -N {session}
```

## New node path structure
```
${nodepath}/
    shared/
       	bin/
       	[lib/]
       	...
    ${host_idx}
        source/
       	    stdin (file)
       	    0
       	    1
       	    2...
        sinks/
       	    stdout (file)
       	    {sink name1}/
                0
       	        1
       	        2...
            {sink name2}/
       	       	....
        err
   in_${host_idx}  - deprecated
   err_${host_idx} - deprecated
```
