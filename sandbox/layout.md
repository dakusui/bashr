bred compose task : arg

/usr
  /local
    /bin
      bred
      bred-core
      xbred
      brp
~
  /.bred                 - basedir
    /conf                - confdir
      hosts              - hosts file
    /fs                  - bred file system
    /jm                  - job management
      /{job idx}   
        pid              - pid of a 'bred' process
        job/             - job path. master node only.
          in             - fifo (inbound to master)
          out            - fifo (outbound from master)
        nodes/           - worker nodes only.
          {host idx}/
            in
            err*
