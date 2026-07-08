#!/bin/bash
python merger.py \
  --base-prefix jetson_ \
  --secondary-prefix imx_ \
  JetsonDeploymentTopologyDictionary.json \
  ImxDeploymentTopologyDictionary.json \
  GDSDictionary.json