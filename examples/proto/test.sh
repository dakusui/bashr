#!/bin/sh

function map {
    awk '{
        print $0, "HELLO";
    }'
}

