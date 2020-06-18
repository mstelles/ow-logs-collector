#!/usr/bin/env bash

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#       http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
#
# This script generates a file in go with the license contents as a constant

# Set language to C to make sorting consistent among different environments.

export LANG="C"
export LC_ALL="C"

# Global options
readonly PROGRAM_VERSION="0.1"
readonly PROGRAM_SOURCE="https://github.com/mstelles/ow-logs-collector"
readonly PROGRAM_NAME="$(basename "$0" .sh)"
readonly PROGRAM_DIR="/opt/ow-logs-collector"
readonly COLLECT_DIR="/tmp/${PROGRAM_NAME}"
readonly DAYS_10=$(date -d "-10 days" '+%Y-%m-%d %H:%M')
INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
INSTANCE_PUB_HOSTNAME="$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)"
SSH_KEY="$(echo $(curl -s http://169.254.169.254/latest/meta-data/public-keys/) | cut -d= -f2)"
SSHUSER=$(who am i| awk '{print$1}')

mkdir -p $COLLECT_DIR || echo "Cant create $COLLECT_DIR"
mkdir -p $PROGRAM_DIR || echo "Cant create $PROGRAM_DIR"

sysctl -a > $COLLECT_DIR/sysctl.txt 2>&1
getenforce > $COLLECT_DIR/getenforce.txt 2>&1

#iptables
iptables_info=(
  security
  filter
  mangle
  raw
  nat
)

for iptables_table in "${iptables_info[@]}"; do
  iptables -v -n -x -L -t $iptables_table > $COLLECT_DIR/iptables-$iptables_table.txt 2> $COLLECT_DIR/iptables-$iptables_table-err.txt
done

#misc info
misc_array=(
  ami-id
  security-groups
  events/maintenance/history
  iam/info
)

for misc_info in "${misc_array[@]}"; do
  echo "Collecting meta-data: $misc_info" >> /tmp/${PROGRAM_NAME}/misc_info.txt
  curl -s http://169.254.169.254/latest/meta-data/$misc_info >> /tmp/${PROGRAM_NAME}/misc_info.txt
  echo >> /tmp/${PROGRAM_NAME}/misc_info.txt
done

file_array=(
  /var/log/messages
  /var/log/cloud-init.log
  /var/log/cloud-init-output.log
  /var/log/cron
  /var/log/secure
)

for collect_files in "${file_array[@]}"; do
  echo "Processing $collect_files file ..."
  cp $collect_files $COLLECT_DIR
done

dir_array=(
  /var/lib/aws/opsworks/chef/
  /var/log/aws/opsworks/
  /etc/
)

for collect_dirs in "${dir_array[@]}"; do
  echo "Compacting $collect_dirs dir ..."
  dir_file_name=$(echo $collect_dirs | tr \/ \_ | cut -c 2-).tar.bz2
  tar cjf $COLLECT_DIR/$dir_file_name $collect_dirs
done

mkdir $PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID || echo "Can't create $PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID"

mv $COLLECT_DIR/* $PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID
echo "Generating the final file: $PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID.tar.bz2"
tar cjf $PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID.tar.bz2 $PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID
chmod 644 $PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID.tar.bz2

echo "To download this file, please try the below command from a source with SSH access to this instance"
echo "scp -i $SSH_KEY.pem $SSHUSER@$INSTANCE_PUB_HOSTNAME:$PROGRAM_DIR/ow-logs-collector-$INSTANCE_ID.tar.bz2 ."
