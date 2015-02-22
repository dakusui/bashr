```
    

```

## bmap ##
* In
  * Args
    + key column (specifies where K1 column is in each line)
  * Stdin
    + [(K1,V1),...]
* Out
  * [(K2,V2),...]
* Procedures
  1. init (t.b.d.)
    * User map function instances are started and start listening remotelly.
  2. brp (write - distribute) - 
    * with specified key column
	* the out_files are named pipes.
  3. brm (read - collect)

## bred ##
* In
  * Args
    + key column (specifies where K2 column is in each line)
  * Stdin
    + [(K1,V1),...]
* Out
  * [(K2,V2),...]
* Procedures
  1. init (t.b.d.)
    * User reduce function container instances are started and start listening remotelly.
	* User reduce function is executed from insider its container
	* The container is an awk loop.
	* Inside the loop there is a line like '{print ... | user reduce function ...} *
	* The container always insert K2 at the first column of its output automatically *
  2. brp (write - distribute) - 
    * with specified key column
	* the out_files are named pipes.
  3. brm (read - collect)

## User map function ##

* In
  * Args
    + (None)
  * Stdin
    + [(K1,V1),...]
* Out
  * [(K2,V2),...]
* Notes
  * K2 must comes at first column in each line of output.



## User reduce function ##
* In
 * Args
  * 1: K2
 * Stdin
  * [V2,...]
* Out
 * [*]


## Environment varialbles given to user functions ##
* ```BMAPRED_PART_ID```
 * partition id
