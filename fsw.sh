#!/bin/bash

PYTHON_BUILD=./build-python-fprime
BUILD_AUTOMATIC=./build-fprime-automatic-native


if test -d "$PYTHON_BUILD"; then
    rm -r $PYTHON_BUILD/*
else
    mkdir $PYTHON_BUILD
fi

find ./Components/ -type f -name "*Component.py" | xargs cp -t $PYTHON_BUILD
find ./Components/ -type f -name "*resnet*.py" | xargs cp -t $PYTHON_BUILD
cp $BUILD_AUTOMATIC/fprime_pybind.py $PYTHON_BUILD

cp $BUILD_AUTOMATIC/lib/Linux/libpython_extension.so $PYTHON_BUILD


cd $PYTHON_BUILD
mv libpython_extension.so python_extension.so
ln python_extension.so Fw.so
ln python_extension.so Components.so
