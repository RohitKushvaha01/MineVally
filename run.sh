#!/bin/bash
cmake . && make -j$(nproc) && ./MineVally
